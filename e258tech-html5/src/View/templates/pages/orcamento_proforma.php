<?php

    $id = $app->request->queryInt('id', 0);

    $resp = $app->nexora->call('GET', "/api/faturacao/quotes/$id");
    if ($resp['status'] !== 200) {
        header('Location: /nexora/faturacao/orcamentos');
        exit;
    }
    $orcamento = $resp['body']['orcamento'] ?? [];
    $itens     = $resp['body']['itens'] ?? [];

    $customerId = $orcamento['customer_id'];
    $cliente    = $app->nexora->call('GET', '/api/clientes/' . $customerId)['body'] ?? [];

    $clienteEnderecos = $app->nexora->call('GET', '/api/clientes/' . $customerId . '/enderecos')['body'] ?? [];
    $clienteEndereco  = null;
    foreach ($clienteEnderecos as $e) {
        if (! empty($e['principal'])) { $clienteEndereco = $e; break; }
    }
    $clienteEndereco ??= $clienteEnderecos[0] ?? null;

    $companies = $app->nexora->call('GET', '/api/companies')['body'] ?? [];
    $company   = $companies[0] ?? null;

    $tax = $companyEndereco = $companyContacto = null;
    if ($company) {
        $cid = $company['id'];

        $tax = $app->nexora->call('GET', "/api/companies/$cid/tax-info")['body'] ?? null;

        $addrs = $app->nexora->call('GET', "/api/companies/$cid/addresses")['body'] ?? [];
        foreach ($addrs as $a) {
            if (($a['tipo'] ?? '') === 'principal') { $companyEndereco = $a; break; }
        }
        $companyEndereco ??= $addrs[0] ?? null;

        $contacts = $app->nexora->call('GET', "/api/companies/$cid/contacts")['body'] ?? [];
        foreach ($contacts as $c) {
            if (! empty($c['principal'])) { $companyContacto = $c; break; }
        }
        $companyContacto ??= $contacts[0] ?? null;
    }

    $companyNome = ! empty($company['nome_comercial']) ? $company['nome_comercial'] : ($company['nome'] ?? '—');

    $subtotal      = 0.0;
    $descontoTotal = 0.0;
    foreach ($itens as $item) {
        $base = (float) $item['quantidade'] * (float) $item['preco_unitario'];
        $subtotal      += $base;
        $descontoTotal += $base * (float) $item['desconto_percent'] / 100;
    }

    $pageTitle = 'Orçamento ' . ($orcamento['numero'] ?? '');

    $docTitulo = 'ORÇAMENTO';
    $docNumero = $orcamento['numero'] ?? '';

    $docDatasExtra = [
        'Data' => ! empty($orcamento['created_at']) ? date('d/m/Y', strtotime($orcamento['created_at'])) : '—',
    ];

    $notice = 'Proposta de orçamento — sem valor fiscal.';
    if (! empty($orcamento['validade'])) {
        $validadeFmt = date('d/m/Y', strtotime($orcamento['validade']));
        $docDatasExtra['Válido até'] = $validadeFmt;
        $notice .= ' Válido até ' . $validadeFmt . '.';
    }

    $impostoTotal = (float) ($orcamento['imposto_total'] ?? 0);
    $totalGeral   = (float) ($orcamento['total'] ?? 0);
    $moeda        = $orcamento['moeda'] ?? '';
    $observacoes  = $orcamento['observacoes'] ?? null;

    $footerNote = 'Documento gerado em ' . date('d/m/Y H:i') . '.';
    $backUrl    = '/nexora/faturacao/orcamentos/form?id=' . $id;

    include dirname(__DIR__) . '/partials/documento_print.php';
