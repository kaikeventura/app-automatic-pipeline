package com.kaikeventura.app_automatic_pipeline.service;

import com.kaikeventura.app_automatic_pipeline.domain.Event;
import com.kaikeventura.app_automatic_pipeline.domain.Ticket;
import com.kaikeventura.app_automatic_pipeline.repository.EventRepository;
import com.kaikeventura.app_automatic_pipeline.repository.TicketRepository;
import io.awspring.cloud.sqs.operations.SqsTemplate;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TicketService {

    private final TicketRepository ticketRepository;
    private final EventRepository eventRepository;
    private final SqsTemplate sqsTemplate;

    @Value("${aws.sqs.payment-queue}")
    private String paymentQueue;

    @Transactional
    public Ticket purchaseTicket(UUID eventId) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new RuntimeException("Event not found"));

        if (event.getAvailableTickets() <= 0) {
            throw new RuntimeException("No tickets available");
        }

        event.setAvailableTickets(event.getAvailableTickets() - 1);
        eventRepository.save(event);

        Ticket ticket = new Ticket();
        ticket.setEvent(event);
        ticket.setPrice(event.getTicketPrice());
        ticket.setStatus("PENDING");

        Ticket savedTicket = ticketRepository.save(ticket);

        sqsTemplate.send(paymentQueue, savedTicket.getId().toString());

        return savedTicket;
    }
}
