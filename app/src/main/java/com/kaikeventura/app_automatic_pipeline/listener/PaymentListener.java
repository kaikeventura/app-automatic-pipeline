package com.kaikeventura.app_automatic_pipeline.listener;

import com.kaikeventura.app_automatic_pipeline.domain.Event;
import com.kaikeventura.app_automatic_pipeline.domain.Ticket;
import com.kaikeventura.app_automatic_pipeline.repository.EventRepository;
import com.kaikeventura.app_automatic_pipeline.repository.TicketRepository;
import io.awspring.cloud.sqs.annotation.SqsListener;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Component
@RequiredArgsConstructor
public class PaymentListener {

    private final TicketRepository ticketRepository;
    private final EventRepository eventRepository;

    @SqsListener("${aws.sqs.payment-result-queue}")
    @Transactional
    public void listen(PaymentResult result) {
        ticketRepository.findById(UUID.fromString(result.ticketId())).ifPresent(ticket -> {
            boolean success = result.success();
            ticket.setStatus(success ? "PAID" : "FAILED");
            ticketRepository.save(ticket);

            if (!success) {
                // Revert ticket availability if payment failed
                Event event = ticket.getEvent();
                event.setAvailableTickets(event.getAvailableTickets() + 1);
                eventRepository.save(event);
            }
        });
    }

    public record PaymentResult(String ticketId, boolean success) {}
}
