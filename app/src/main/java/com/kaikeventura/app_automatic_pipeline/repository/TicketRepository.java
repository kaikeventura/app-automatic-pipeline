package com.kaikeventura.app_automatic_pipeline.repository;

import com.kaikeventura.app_automatic_pipeline.domain.Ticket;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface TicketRepository extends JpaRepository<Ticket, UUID> {
}
