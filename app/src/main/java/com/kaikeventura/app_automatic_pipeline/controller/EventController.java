package com.kaikeventura.app_automatic_pipeline.controller;

import com.kaikeventura.app_automatic_pipeline.domain.Event;
import com.kaikeventura.app_automatic_pipeline.service.EventService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;

@RestController
@RequestMapping("/events")
@RequiredArgsConstructor
public class EventController {

    private final EventService eventService;

    @PostMapping
    public ResponseEntity<Event> createEvent(
            @RequestParam("name") String name,
            @RequestParam("totalTickets") Integer totalTickets,
            @RequestParam("ticketPrice") BigDecimal ticketPrice,
            @RequestParam("image") MultipartFile image
    ) throws IOException {
        return ResponseEntity.ok(eventService.createEvent(name, totalTickets, ticketPrice, image));
    }
}
