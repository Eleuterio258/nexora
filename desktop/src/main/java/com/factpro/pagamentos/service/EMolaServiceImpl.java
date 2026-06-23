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
 * E-Mola (Movitel Mocambique) payment integration.
 */
public class EMolaServiceImpl implements MobilePaymentService {

    private static final Logger logger = LoggerFactory.getLogger(EMolaServiceImpl.class);

    private final String apiKey;
    private final String baseUrl;
    private final HttpClient httpClient;

    public EMolaServiceImpl() {
        AppConfig config = AppConfig.getInstance();
        this.apiKey = config.getEmolaApiKey() != null ? config.getEmolaApiKey() : "PLACEHOLDER_KEY";
        this.baseUrl = "https://api.emola.co.mz/api/v1/payment";
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(30))
                .build();
    }

    @Override
    public PaymentResponse initiatePayment(String telefone, double amount, String reference) throws Exception {
        logger.info("E-Mola payment: telefone={}, amount={}, ref={}", telefone, amount, reference);

        String jsonBody = String.format(
                "{\"msisdn\":\"%s\",\"amount\":%.2f,\"reference\":\"%s\"}",
                telefone, amount, reference
        );

        // TODO: Replace with real API call when credentials are available
        logger.warn("E-Mola API call simulated (no real credentials). URL: {}", baseUrl);

        PaymentResponse resp = new PaymentResponse();
        resp.setTransactionId("EML" + System.currentTimeMillis());
        resp.setStatus("SUCCESS");
        resp.setReference(reference);
        resp.setAmount(amount);
        resp.setMessage("Pagamento simulado com sucesso (sem credenciais reais)");
        resp.setProvider("emola");
        return resp;
    }

    @Override
    public PaymentStatus checkStatus(String transactionId) throws Exception {
        logger.debug("E-Mola status check for: {}", transactionId);
        return PaymentStatus.SUCCESS;
    }

    @Override
    public String getProviderName() {
        return "E-Mola";
    }
}
