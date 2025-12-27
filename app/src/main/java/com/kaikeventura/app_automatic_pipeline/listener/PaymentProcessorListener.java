package com.kaikeventura.app_automatic_pipeline.listener;

import com.kaikeventura.app_automatic_pipeline.dto.PaymentResult;
import io.awspring.cloud.sqs.annotation.SqsListener;
import io.awspring.cloud.sqs.operations.SqsTemplate;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.Random;

@Component
@RequiredArgsConstructor
@Slf4j
public class PaymentProcessorListener {

    private final SqsTemplate sqsTemplate;

    @Value("${aws.sqs.payment-result-queue}")
    private String paymentResultQueue;

    @SqsListener("${aws.sqs.payment-queue}")
    public void processPayment(String ticketId) {
        log.info("Processing payment for ticket: {}", ticketId);

        // Simulate processing time
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        // 99% success rate
        boolean success = new Random().nextInt(100) < 99;

        PaymentResult result = new PaymentResult(ticketId, success);
        sqsTemplate.send(paymentResultQueue, result);

        log.info("Payment processed for ticket: {}, success: {}", ticketId, success);
    }
}
