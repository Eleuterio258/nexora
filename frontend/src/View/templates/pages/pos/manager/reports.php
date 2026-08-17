<?php
declare(strict_types=1);

$this->layout('pos_top.php');
?>
<div class="container-fluid">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h1 class="h3 mb-0"><i class="bi bi-graph-up"></i> Relatórios POS</h1>
        <span class="badge bg-info text-dark">Portal Gerente</span>
    </div>
    <div class="card">
        <div class="card-body">
            <p>Relatórios de vendas por sessão, terminal, operador e produto.</p>
            <ul class="list-group">
                <li class="list-group-item"><a href="/pos/gerente/relatorios/fecho">Fecho de Caixa</a></li>
                <li class="list-group-item"><a href="#">Vendas por Terminal</a></li>
                <li class="list-group-item"><a href="#">Vendas por Operador</a></li>
                <li class="list-group-item"><a href="#">Produtos Mais Vendidos</a></li>
            </ul>
        </div>
    </div>
</div>
<?php $this->layout('pos_bottom.php'); ?>
