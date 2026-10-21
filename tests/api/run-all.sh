#!/usr/bin/env bash
# 一键执行全部 curl 接口测试（Linux/macOS/Git Bash）
# 用法：API_BASE=http://localhost:8080 bash tests/api/run-all.sh
# 退出码：0 = 全部通过；1 = 存在失败用例
set -u

BASE="${API_BASE:-http://localhost:8080}"
TMP="$(mktemp -d 2>/dev/null || mktemp -d -t qa-api)"
PASS=0
FAIL=0

cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

pass() { PASS=$((PASS + 1)); printf '[PASS] %s %s %s\n' "$1" "$2" "$3"; }
fail() { FAIL=$((FAIL + 1)); printf '[FAIL] %s %s %s\n' "$1" "$2" "$3"; }

expect() {
    local expected="$1" actual="$2" id="$3" name="$4" detail="${5:-}"
    if [ "$expected" = "$actual" ]; then
        pass "$id" "$name" "$detail"
    else
        fail "$id" "$name" "expected=$expected actual=$actual $detail"
    fi
}

status() {
    local out="$1"
    shift
    curl -s -o "$out" -w '%{http_code}' "$@"
}

echo "API 测试开始，目标: $BASE"
echo '------------------------------------------------------------'

# ---------- 医生列表 ----------
s=$(status "$TMP/all.json" "$BASE/api/doctors")
expect 200 "$s" DOC-01 '医生列表 HTTP 200' ''
count=$(grep -o '"id":"doc00[0-9]"' "$TMP/all.json" | wc -l | tr -d ' ')
expect 5 "$count" DOC-02 '医生列表返回 5 条' "count=$count"
if grep -q '"password"' "$TMP/all.json"; then
    fail DOC-03 '响应不含 password 字段' '发现 password 字段'
else
    pass DOC-03 '响应不含 password 字段' ''
fi
s=$(status "$TMP/active.json" "$BASE/api/doctors?active=true")
count=$(grep -o '"id":"doc00[0-9]"' "$TMP/active.json" | wc -l | tr -d ' ')
expect 4 "$count" DOC-04 'active=true 仅返回 4 条' "HTTP $s"
s=$(status "$TMP/bad.json" "$BASE/api/doctors?active=abc")
expect 400 "$s" DOC-05 '非法参数返回 400' "$(cat "$TMP/bad.json")"

# ---------- 患者认证 ----------
STAMP="$(date +%H%M%S)"
USER="api_sh_${STAMP}"
WEAK="api_sh_weak_${STAMP}"
MISSING="api_sh_missing_${STAMP}"

cat >"$TMP/register.json" <<EOF
{"username":"${USER}","password":"123456","name":"接口测试患者","birthday":"1995-05-20"}
EOF
cat >"$TMP/login.json" <<EOF
{"username":"${USER}","password":"123456"}
EOF
cat >"$TMP/wrong.json" <<EOF
{"username":"${USER}","password":"wrong-password"}
EOF
cat >"$TMP/unknown.json" <<EOF
{"username":"no_such_${STAMP}","password":"123456"}
EOF
cat >"$TMP/weak.json" <<EOF
{"username":"${WEAK}","password":"12345","name":"弱密码"}
EOF
cat >"$TMP/missing.json" <<EOF
{"username":"${MISSING}","password":"123456"}
EOF

s=$(status "$TMP/reg.json" -X POST -H 'Content-Type: application/json' --data-binary "@$TMP/register.json" "$BASE/api/auth/patient/register")
expect 201 "$s" AUTH-01 '注册成功返回 201' "$(cat "$TMP/reg.json")"

s=$(status "$TMP/dup.json" -X POST -H 'Content-Type: application/json' --data-binary "@$TMP/register.json" "$BASE/api/auth/patient/register")
expect 409 "$s" AUTH-02 '重复用户名返回 409' "$(cat "$TMP/dup.json")"

s=$(status "$TMP/weak-out.json" -X POST -H 'Content-Type: application/json' --data-binary "@$TMP/weak.json" "$BASE/api/auth/patient/register")
expect 400 "$s" AUTH-03 '密码不足 6 位返回 400' "$(cat "$TMP/weak-out.json")"

s=$(status "$TMP/missing-out.json" -X POST -H 'Content-Type: application/json' --data-binary "@$TMP/missing.json" "$BASE/api/auth/patient/register")
expect 400 "$s" AUTH-04 '缺少姓名返回 400' "$(cat "$TMP/missing-out.json")"

s=$(status "$TMP/login-out.json" -X POST -H 'Content-Type: application/json' --data-binary "@$TMP/login.json" "$BASE/api/auth/patient/login")
expect 200 "$s" AUTH-05 '登录成功返回 200' ''
TOKEN=$(sed -n 's/.*"token":"\([^"]*\)".*/\1/p' "$TMP/login-out.json" | head -n 1)
if [ "${#TOKEN}" -ge 32 ]; then
    pass AUTH-06 '登录返回 token 且长度 >= 32' "len=${#TOKEN}"
else
    fail AUTH-06 '登录返回 token 且长度 >= 32' "len=${#TOKEN}"
fi

s=$(status "$TMP/wrong-out.json" -X POST -H 'Content-Type: application/json' --data-binary "@$TMP/wrong.json" "$BASE/api/auth/patient/login")
expect 401 "$s" AUTH-07 '密码错误返回 401' "$(cat "$TMP/wrong-out.json")"

s=$(status "$TMP/unknown-out.json" -X POST -H 'Content-Type: application/json' --data-binary "@$TMP/unknown.json" "$BASE/api/auth/patient/login")
expect 401 "$s" AUTH-08 '不存在用户返回 401' "$(cat "$TMP/unknown-out.json")"
if grep -q '用户名或密码错误' "$TMP/wrong-out.json" && grep -q '用户名或密码错误' "$TMP/unknown-out.json"; then
    pass AUTH-09 '两种失败文案一致（防枚举）' ''
else
    fail AUTH-09 '两种失败文案一致（防枚举）' '文案不一致'
fi

s=$(status "$TMP/me.json" -H "Authorization: Bearer $TOKEN" "$BASE/api/auth/patient/me")
expect 200 "$s" AUTH-10 '有效 token 获取当前用户' ''

s=$(status "$TMP/me-no.json" "$BASE/api/auth/patient/me")
expect 401 "$s" AUTH-11 '无 token 返回 401' ''

s=$(status "$TMP/me-forged.json" -H 'Authorization: Bearer forged-token' "$BASE/api/auth/patient/me")
expect 401 "$s" AUTH-12 '伪造 token 返回 401' ''

s=$(status "$TMP/logout.json" -X POST -H "Authorization: Bearer $TOKEN" "$BASE/api/auth/patient/logout")
expect 204 "$s" AUTH-13 '登出返回 204' ''

s=$(status "$TMP/me-after.json" -H "Authorization: Bearer $TOKEN" "$BASE/api/auth/patient/me")
expect 401 "$s" AUTH-14 '登出后 token 失效返回 401' ''

echo '------------------------------------------------------------'
echo "总计 $((PASS + FAIL)) 条，通过 ${PASS} 条，失败 ${FAIL} 条"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
