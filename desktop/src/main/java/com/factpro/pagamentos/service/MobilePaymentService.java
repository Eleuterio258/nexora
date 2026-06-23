package com.factpro.pagamentos.service;

import com.factpro.pagamentos.model.PaymentResponse;

public interface MobilePaymentService {
    PaymentResponse initiatePayment(String telefone, double amount, String reference) throws Exception;
    PaymentStatus checkStatus(String transactionId) throws Exception;
    String getProviderName();

    enum PaymentStatus { PENDING, SUCCESS, FAILED, TIMEOUT }
}
