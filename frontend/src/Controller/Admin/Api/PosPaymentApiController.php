<?php

declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Core\Application;
use E258Tech\Infrastructure\Nexora\ApiResponse;

/**
 * API POS para pagamentos móveis e vendas via PayCore.
 *
 * Como o backend PayCore não tem gateway M-Pesa/eMola dedicado, estes endpoints
 * simulam o fluxo usando transações WALLET (/api/v1/transactions).
 */
final class PosPaymentApiController
{
    public static function iniciarPagamento(): never
    {
        $app = self::requireAuth();
        $body = self::jsonBody();

        try {
            $amount = (float) ($body['amount'] ?? 0);
            if ($amount <= 0) {
                self::jsonError('O valor deve ser superior a zero.', 422);
            }

            $items = $body['items'] ?? [];
            if (empty($items)) {
                self::jsonError('O carrinho esta vazio.', 422);
            }

            $gateway = $body['gateway'] ?? 'M-Pesa';
            $phone = $body['phone'] ?? null;
            $manualRef = $body['reference'] ?? null;

            $transaction = $app->payCorePayment->createMobilePayment($items, [
                'gateway' => $gateway,
                'phone' => $phone,
                'paymentType' => $gateway,
                'operatorId' => $app->session->user()['id'] ?? null,
            ]);

            $reference = $manualRef ?: ($transaction['reference'] ?? null);

            self::json([
                'ok' => true,
                'reference' => $reference,
                'amount' => $amount,
                'gateway' => $gateway,
                'phone' => $phone,
                'status' => $transaction['status'] ?? 'PENDING',
                'instructions' => 'Confirme a transacao no seu telemovel. O estado sera actualizado automaticamente.',
            ]);
        } catch (\Throwable $e) {
            error_log('Iniciar pagamento movel erro: ' . $e->getMessage());
            self::jsonError($e->getMessage(), 500);
        }
    }

    public static function statusPagamento(): never
    {
        $app = self::requireAuth();
        $reference = $_GET['reference'] ?? '';

        if ($reference === '') {
            self::jsonError('Referencia obrigatoria.', 422);
        }

        try {
            $transaction = $app->payCorePayment->statusByReference($reference);
            self::json([
                'ok' => true,
                'reference' => $reference,
                'status' => $transaction['status'] ?? 'UNKNOWN',
                'amount' => $transaction['total'] ?? 0,
            ]);
        } catch (\Throwable $e) {
            error_log('Status pagamento movel erro: ' . $e->getMessage());
            self::jsonError($e->getMessage(), 500);
        }
    }

    public static function registarVenda(): never
    {
        $app = self::requireAuth();
        $body = self::jsonBody();

        try {
            $amount = (float) ($body['amount'] ?? 0);
            if ($amount <= 0) {
                self::jsonError('O valor deve ser superior a zero.', 422);
            }

            $items = $body['items'] ?? [];
            if (empty($items)) {
                self::jsonError('O carrinho esta vazio.', 422);
            }

            $method = match (strtolower((string) ($body['payment_method'] ?? 'dinheiro'))) {
                'm-pesa', 'mpesa', 'e-mola', 'emola' => 'WALLET',
                'cartao', 'cartão' => 'CARD',
                'transferencia', 'transferência' => 'BANK_TRANSFER',
                default => 'CASH',
            };

            $transaction = $app->payCorePayment->createSale($items, [
                'paymentMethod' => $method,
                'paymentType' => $body['payment_method'] ?? null,
                'operatorId' => $app->session->user()['id'] ?? null,
                'discount' => (float) ($body['discount'] ?? 0),
            ]);

            self::json([
                'ok' => true,
                'reference' => $transaction['reference'] ?? null,
                'total' => $transaction['total'] ?? 0,
                'status' => $transaction['status'] ?? 'UNKNOWN',
            ]);
        } catch (\Throwable $e) {
            error_log('Registar venda erro: ' . $e->getMessage());
            self::jsonError($e->getMessage(), 500);
        }
    }

    private static function requireAuth(): Application
    {
        $app = Application::bootstrap();
        if (!$app->session->isAuthenticated()) {
            self::jsonError('Nao autenticado.', 401);
        }
        return $app;
    }

    /**
     * @return array<string, mixed>
     */
    private static function jsonBody(): array
    {
        $input = file_get_contents('php://input');
        if ($input === '' || $input === false) {
            return [];
        }
        $decoded = json_decode($input, true);
        return is_array($decoded) ? $decoded : [];
    }

    /**
     * @param array<string, mixed> $body
     */
    private static function json(array $body, int $status = 200): never
    {
        header('Content-Type: application/json');
        http_response_code($status);
        echo json_encode($body, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
        exit;
    }

    private static function jsonError(string $message, int $status = 500): never
    {
        self::json(['ok' => false, 'erro' => $message], $status);
    }
}
