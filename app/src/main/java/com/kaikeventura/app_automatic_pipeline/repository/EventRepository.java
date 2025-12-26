package com.kaikeventura.app_automatic_pipeline.repository;

import com.kaikeventura.app_automatic_pipeline.domain.Event;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface EventRepository extends JpaRepository<Event, UUID> {
}
