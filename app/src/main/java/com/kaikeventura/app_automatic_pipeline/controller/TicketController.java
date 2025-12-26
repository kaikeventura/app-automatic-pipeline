package com.kaikeventura.app_automatic_pipeline.controller;

import com.kaikeventura.app_automatic_pipeline.domain.Ticket;
import com.kaikeventura.app_automatic_pipeline.service.TicketService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/tickets")
@RequiredArgsConstructor
public class TicketController {

    private final TicketService ticketService;

    @PostMapping("/purchase/{eventId}")
    public ResponseEntity<Ticket> purchaseTicket(@PathVariable UUID eventId) {
        return ResponseEntity.ok(ticketService.purchaseTicket(eventId));
    }
}
