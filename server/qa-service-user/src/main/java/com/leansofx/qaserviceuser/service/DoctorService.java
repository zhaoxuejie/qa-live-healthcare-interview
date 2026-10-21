package com.leansofx.qaserviceuser.service;

import com.leansofx.qaserviceuser.dto.DoctorDto;
import com.leansofx.qaserviceuser.entity.Doctor;
import com.leansofx.qaserviceuser.repository.DoctorRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class DoctorService {

    private final DoctorRepository doctorRepository;

    public DoctorService(DoctorRepository doctorRepository) {
        this.doctorRepository = doctorRepository;
    }

    @Transactional(readOnly = true)
    public List<DoctorDto> listDoctors(boolean activeOnly) {
        List<Doctor> doctors = activeOnly
                ? doctorRepository.findByIsActiveTrueOrderByIdAsc()
                : doctorRepository.findAllByOrderByIdAsc();
        return doctors.stream().map(DoctorDto::from).toList();
    }

    /**
     * 医生登录：演示项目密码以明文存于库中（API 不返回），仅做等值校验。
     */
    @Transactional(readOnly = true)
    public Optional<DoctorDto> login(String username, String password) {
        if (username == null || password == null) {
            return Optional.empty();
        }
        return doctorRepository.findByUsername(username)
                .filter(doctor -> password.equals(doctor.getPassword()))
                .map(DoctorDto::from);
    }
}
