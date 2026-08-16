<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Infrastructure\Http;

use E258Tech\Faturacao\Domain\Service\CompanyInfoProviderInterface;
use E258Tech\Faturacao\Domain\ValueObject\CompanyInfo;

/**
 * GET /api/companies devolve só as empresas do tenant autenticado (o
 * backend já filtra por tenant_id para quem não é superadmin), por isso
 * a primeira da lista é a empresa "principal" na prática — não há aqui
 * noção de multi-empresa por tenant do lado do phc.
 */
final class HttpCompanyInfoProvider implements CompanyInfoProviderInterface
{
    public function __construct(private ApiClient $client)
    {
    }

    public function getPrimary(): ?CompanyInfo
    {
        try {
            $companies = $this->client->get('/api/companies', ['limit' => 1]);
        } catch (ApiException) {
            return null;
        }

        $rows = $companies['data'] ?? $companies;
        $first = is_array($rows) ? reset($rows) : false;
        if ($first === false || !is_array($first) || !isset($first['id'])) {
            return null;
        }

        $name = (string) ($first['nome_comercial'] ?? $first['nome'] ?? '');
        $nuit = '';
        try {
            $taxInfo = $this->client->get('/api/companies/' . $first['id'] . '/tax-info');
            $nuit = (string) ($taxInfo['nuit'] ?? '');
        } catch (ApiException) {
            // Empresa pode ainda não ter informação fiscal configurada —
            // mostra-se o nome sem NUIT em vez de falhar tudo.
        }

        return new CompanyInfo($name, $nuit);
    }
}
