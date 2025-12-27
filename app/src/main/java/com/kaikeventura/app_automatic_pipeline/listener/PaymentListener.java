package com.kaikeventura.app_automatic_pipeline.listener;

import com.kaikeventura.app_automatic_pipeline.domain.Event;
import com.kaikeventura.app_automatic_pipeline.dto.PaymentResult;
import com.kaikeventura.app_automatic_pipeline.repository.EventRepository;
import com.kaikeventura.app_automatic_pipeline.repository.TicketRepository;
import io.awspring.cloud.sqs.annotation.SqsListener;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Component
@RequiredArgsConstructor
@Slf4j
public class PaymentListener {

    private final TicketRepository ticketRepository;
    private final EventRepository eventRepository;

    @SqsListener("${aws.sqs.payment-result-queue}")
    @Transactional
    public void listen(PaymentResult result) {
        log.info("Received payment result for ticket: {}, success: {}", result.ticketId(), result.success());
        ticketRepository.findById(UUID.fromString(result.ticketId())).ifPresent(ticket -> {
            boolean success = result.success();
            ticket.setStatus(success ? "PAID" : "FAILED");
            ticketRepository.save(ticket);

            if (!success) {
                // Revert ticket availability if payment failed
                Event event = ticket.getEvent();
                event.setAvailableTickets(event.getAvailableTickets() + 1);
                eventRepository.save(event);
                log.info("Reverted ticket availability for event: {}", event.getId());
            }
        });
    }
}
