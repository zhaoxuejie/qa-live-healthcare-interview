package com.leansofx.qaserviceuser.repository;

import com.leansofx.qaserviceuser.entity.Doctor;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface DoctorRepository extends JpaRepository<Doctor, String> {

    List<Doctor> findAllByOrderByIdAsc();

    List<Doctor> findByIsActiveTrueOrderByIdAsc();

    Optional<Doctor> findByUsername(String username);
}
