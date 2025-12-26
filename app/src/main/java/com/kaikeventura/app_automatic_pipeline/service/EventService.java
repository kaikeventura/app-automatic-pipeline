package com.kaikeventura.app_automatic_pipeline.service;

import com.kaikeventura.app_automatic_pipeline.domain.Event;
import com.kaikeventura.app_automatic_pipeline.repository.EventRepository;
import io.awspring.cloud.s3.S3Resource;
import io.awspring.cloud.s3.S3Template;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class EventService {

    private final EventRepository eventRepository;
    private final S3Template s3Template;

    @Value("${aws.s3.bucket}")
    private String bucketName;

    public Event createEvent(String name, Integer totalTickets, BigDecimal ticketPrice, MultipartFile image) throws IOException {
        String imageUrl = uploadImage(image);

        Event event = new Event();
        event.setName(name);
        event.setTotalTickets(totalTickets);
        event.setAvailableTickets(totalTickets);
        event.setTicketPrice(ticketPrice);
        event.setImageUrl(imageUrl);

        return eventRepository.save(event);
    }

    private String uploadImage(MultipartFile image) throws IOException {
        String key = UUID.randomUUID() + "-" + image.getOriginalFilename();
        S3Resource resource = s3Template.upload(bucketName, key, image.getInputStream());
        return resource.getURL().toString();
    }
}
