package com.leansofx.qaserviceuser.service;

import com.leansofx.qaserviceuser.dto.DoctorDto;
import com.leansofx.qaserviceuser.entity.Doctor;
import com.leansofx.qaserviceuser.repository.DoctorRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

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
}
