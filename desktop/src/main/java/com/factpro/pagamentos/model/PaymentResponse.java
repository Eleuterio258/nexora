package com.factpro.pagamentos.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PaymentResponse {
    private String transactionId;
    private String status;
    private String reference;
    private double amount;
    private String message;
    private String provider;
}
