<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Sistema;

use E258Tech\Model\Service\NexoraService;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Contract\NexoraGateway;

final class SistemaConfiguracaoService extends NexoraService
{
    private const ESCOPOS = ['global', 'tenant', 'user'];

    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    public function saveSetting(array $payload): array
    {
        if (trim((string) ($payload['chave'] ?? '')) === '') {
            throw new OperationException('A chave e obrigatoria.');
        }
        if (!in_array($payload['escopo'] ?? 'tenant', self::ESCOPOS, true)) {
            $payload['escopo'] = 'tenant';
        }

        $response = $this->gateway->request('POST', '/api/system/settings', $payload);
        $this->ensureSuccess($response, 'Erro ao guardar a definicao.');

        return ['ok' => true, 'msg' => 'Definicao guardada com sucesso.'];
    }

    public function createCurrency(array $payload): array
    {
        if (trim((string) ($payload['codigo'] ?? '')) === '') {
            throw new OperationException('O codigo da moeda e obrigatorio.');
        }
        if (trim((string) ($payload['nome'] ?? '')) === '') {
            throw new OperationException('O nome da moeda e obrigatorio.');
        }

        $response = $this->gateway->request('POST', '/api/system/currencies', $payload);
        $this->ensureSuccess($response, 'Erro ao criar a moeda.');

        return ['ok' => true, 'msg' => 'Moeda criada com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function createExchangeRate(array $payload): array
    {
        if (($payload['from_currency_id'] ?? 0) <= 0) {
            throw new OperationException('A moeda de origem e obrigatoria.');
        }
        if (($payload['to_currency_id'] ?? 0) <= 0) {
            throw new OperationException('A moeda de destino e obrigatoria.');
        }
        if (($payload['rate'] ?? 0) <= 0) {
            throw new OperationException('A taxa de cambio e invalida.');
        }

        $response = $this->gateway->request('POST', '/api/system/exchange-rates', $payload);
        $this->ensureSuccess($response, 'Erro ao criar a taxa de cambio.');

        return ['ok' => true, 'msg' => 'Taxa de cambio criada com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function createCountry(array $payload): array
    {
        if (trim((string) ($payload['codigo'] ?? '')) === '') {
            throw new OperationException('O codigo do pais e obrigatorio.');
        }
        if (trim((string) ($payload['nome'] ?? '')) === '') {
            throw new OperationException('O nome do pais e obrigatorio.');
        }

        $response = $this->gateway->request('POST', '/api/system/countries', $payload);
        $this->ensureSuccess($response, 'Erro ao criar o pais.');

        return ['ok' => true, 'msg' => 'Pais criado com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function createCity(array $payload): array
    {
        if (trim((string) ($payload['nome'] ?? '')) === '') {
            throw new OperationException('O nome da cidade e obrigatorio.');
        }

        $response = $this->gateway->request('POST', '/api/system/cities', $payload);
        $this->ensureSuccess($response, 'Erro ao criar a cidade.');

        return ['ok' => true, 'msg' => 'Cidade criada com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function createLanguage(array $payload): array
    {
        if (trim((string) ($payload['codigo'] ?? '')) === '') {
            throw new OperationException('O codigo do idioma e obrigatorio.');
        }
        if (trim((string) ($payload['nome'] ?? '')) === '') {
            throw new OperationException('O nome do idioma e obrigatorio.');
        }

        $response = $this->gateway->request('POST', '/api/system/languages', $payload);
        $this->ensureSuccess($response, 'Erro ao criar o idioma.');

        return ['ok' => true, 'msg' => 'Idioma criado com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function createEmailTemplate(array $payload): array
    {
        if (trim((string) ($payload['codigo'] ?? '')) === '') {
            throw new OperationException('O codigo do modelo e obrigatorio.');
        }
        if (trim((string) ($payload['assunto'] ?? '')) === '') {
            throw new OperationException('O assunto e obrigatorio.');
        }
        if (trim((string) ($payload['corpo'] ?? '')) === '') {
            throw new OperationException('O corpo do modelo e obrigatorio.');
        }

        $response = $this->gateway->request('POST', '/api/system/email-templates', $payload);
        $this->ensureSuccess($response, 'Erro ao criar o modelo de email.');

        return ['ok' => true, 'msg' => 'Modelo de email criado com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function createSmsTemplate(array $payload): array
    {
        if (trim((string) ($payload['codigo'] ?? '')) === '') {
            throw new OperationException('O codigo do modelo e obrigatorio.');
        }
        if (trim((string) ($payload['corpo'] ?? '')) === '') {
            throw new OperationException('O corpo do modelo e obrigatorio.');
        }

        $response = $this->gateway->request('POST', '/api/system/sms-templates', $payload);
        $this->ensureSuccess($response, 'Erro ao criar o modelo de SMS.');

        return ['ok' => true, 'msg' => 'Modelo de SMS criado com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function createIntegration(array $payload): array
    {
        if (trim((string) ($payload['codigo'] ?? '')) === '') {
            throw new OperationException('O codigo da integracao e obrigatorio.');
        }
        if (trim((string) ($payload['nome'] ?? '')) === '') {
            throw new OperationException('O nome da integracao e obrigatorio.');
        }

        $configuracao = $payload['configuracao'] ?? null;
        if (is_string($configuracao) && trim($configuracao) !== '') {
            $decoded = json_decode($configuracao, true);
            if (json_last_error() !== JSON_ERROR_NONE) {
                throw new OperationException('A configuracao deve ser um JSON valido.');
            }
            $payload['configuracao'] = $decoded;
        } elseif ($configuracao === '' || $configuracao === null) {
            unset($payload['configuracao']);
        }

        $response = $this->gateway->request('POST', '/api/system/integrations', $payload);
        $this->ensureSuccess($response, 'Erro ao criar a integracao.');

        return ['ok' => true, 'msg' => 'Integracao criada com sucesso.', 'id' => $response->body['id'] ?? null];
    }
}
