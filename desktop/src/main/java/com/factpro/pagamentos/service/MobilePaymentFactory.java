package com.factpro.pagamentos.service;

/**
 * Factory for mobile payment providers.
 */
public class MobilePaymentFactory {

    public static MobilePaymentService getProvider(String provider) {
        return switch (provider.toLowerCase()) {
            case "mpesa" -> new MPesaServiceImpl();
            case "emola" -> new EMolaServiceImpl();
            default -> throw new IllegalArgumentException("Unknown provider: " + provider);
        };
    }
}
