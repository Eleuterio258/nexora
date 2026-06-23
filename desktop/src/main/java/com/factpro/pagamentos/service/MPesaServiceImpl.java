package com.factpro.pagamentos.service;

import com.factpro.config.AppConfig;
import com.factpro.pagamentos.model.PaymentResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

/**
 * M-Pesa (Vodacom Mocambique) payment integration.
 * Uses C2B (Customer-to-Business) API.
 */
public class MPesaServiceImpl implements MobilePaymentService {

    private static final Logger logger = LoggerFactory.getLogger(MPesaServiceImpl.class);

    private final String apiKey;
    private final String publicKey;
    private final String baseUrl;
    private final String providerId;
    private final HttpClient httpClient;

    public MPesaServiceImpl() {
        AppConfig config = AppConfig.getInstance();
        this.apiKey = config.getMpesaApiKey() != null ? config.getMpesaApiKey() : "PLACEHOLDER_KEY";
        this.publicKey = config.getMpesaPublicKey() != null ? config.getMpesaPublicKey() : "";
        this.baseUrl = "https://api.mpesa.co.mz/v1";
        this.providerId = "mpesa";
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(30))
                .build();
    }

    @Override
    public PaymentResponse initiatePayment(String telefone, double amount, String reference) throws Exception {
        logger.info("M-Pesa payment: telefone={}, amount={}, ref={}", telefone, amount, reference);

        String url = baseUrl + "/c2b/payment";
        String jsonBody = String.format(
                "{\"input_Country\":\"Mozambique\",\"input_Amount\":\"%.2f\"," +
                "\"input_CustomerMSISDN\":\"%s\",\"input_ThirdPartyReference\":\"%s\"," +
                "\"input_ServiceProviderCode\":\"%s\"}",
                amount, telefone, reference, providerId
        );

        // TODO: Replace with real API call when credentials are available
        // For now, simulate a successful payment
        logger.warn("M-Pesa API call simulated (no real credentials). URL: {}", url);

        /* Real implementation:
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + getAccessToken())
                .POST(HttpRequest.BodyPublishers.ofString(jsonBody))
                .build();

        HttpResponse<String> response = httpClient.send(request,
                HttpResponse.BodyHandlers.ofString());
        return parsePaymentResponse(response.body());
        */

        // Simulated response
        PaymentResponse resp = new PaymentResponse();
        resp.setTransactionId("MPS" + System.currentTimeMillis());
        resp.setStatus("SUCCESS");
        resp.setReference(reference);
        resp.setAmount(amount);
        resp.setMessage("Pagamento simulado com sucesso (sem credenciais reais)");
        resp.setProvider("mpesa");
        return resp;
    }

    @Override
    public PaymentStatus checkStatus(String transactionId) throws Exception {
        // TODO: Implement status check via M-Pesa API
        logger.debug("M-Pesa status check for: {}", transactionId);
        return PaymentStatus.SUCCESS;
    }

    @Override
    public String getProviderName() {
        return "M-Pesa";
    }

    private String getAccessToken() throws Exception {
        // TODO: Implement OAuth token retrieval from M-Pesa API
        return apiKey;
    }

    private PaymentResponse parsePaymentResponse(String jsonBody) {
        // TODO: Parse JSON response using Jackson
        return new PaymentResponse();
    }
}
