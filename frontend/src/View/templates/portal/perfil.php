<?php
declare(strict_types=1);

$pageTitle  = 'Meu Perfil';
$activePage = 'perfil';

$me         = $portalData['me']['body'] ?? [];
$alunoInfo  = $me;
$matricula  = $me['matricula_activa'] ?? null;
$encarregados = $me['encarregados'] ?? [];

include dirname(__FILE__) . '/layout_top.php';
?>

<div style="display:grid;grid-template-columns:300px 1fr;gap:1.25rem;align-items:start">

    <!-- Coluna esquerda: avatar + identidade -->
    <div style="display:flex;flex-direction:column;gap:1rem">

        <!-- Foto + nome -->
        <div class="portal-card" style="text-align:center;padding:1.5rem 1rem">
            <?php if (!empty($me['fotografia_url'])): ?>
            <img src="<?= htmlspecialchars($me['fotografia_url']) ?>"
                 style="width:100px;height:100px;border-radius:50%;object-fit:cover;border:3px solid #E0F2FE;margin-bottom:.75rem"
                 alt="Foto do aluno">
            <?php else: ?>
            <div style="width:100px;height:100px;border-radius:50%;background:linear-gradient(135deg,#0369A1,#38BDF8);
                        display:flex;align-items:center;justify-content:center;margin:0 auto .75rem;
                        font-size:2.2rem;font-weight:800;color:#fff">
                <?= mb_strtoupper(mb_substr($me['nome'] ?? 'A', 0, 1)) ?>
            </div>
            <?php endif; ?>
            <h2 style="font-size:1rem;font-weight:700;color:#0C4A6E;margin:0 0 .25rem">
                <?= htmlspecialchars($me['nome'] ?? '') ?>
            </h2>
            <div style="font-size:.8rem;color:#0EA5E9;font-weight:600">
                <?= htmlspecialchars($me['codigo'] ?? '') ?>
            </div>
            <?php if (!empty($me['portal_email'])): ?>
            <div style="font-size:.75rem;color:#64748B;margin-top:.35rem">
                <i class="fa-solid fa-envelope" style="font-size:.68rem"></i>
                <?= htmlspecialchars($me['portal_email']) ?>
                <?php if (!empty($me['portal_email_verificado'])): ?>
                <i class="fa-solid fa-circle-check" style="color:#22C55E;font-size:.7rem" title="Email verificado"></i>
                <?php else: ?>
                <i class="fa-solid fa-clock" style="color:#F59E0B;font-size:.7rem" title="Email não verificado"></i>
                <?php endif; ?>
            </div>
            <?php endif; ?>
            <div style="margin-top:.6rem">
                <?php
                $estado = $me['estado'] ?? 'activo';
                $estadoBadge = match($estado) {
                    'activo'     => ['badge-green', 'Activo'],
                    'transferido'=> ['badge-yellow','Transferido'],
                    'graduado'   => ['badge-blue',  'Graduado'],
                    'suspenso'   => ['badge-red',   'Suspenso'],
                    'inactivo'   => ['badge-gray',  'Inactivo'],
                    default      => ['badge-gray',   ucfirst($estado)],
                };
                ?>
                <span class="portal-badge <?= $estadoBadge[0] ?>"><?= $estadoBadge[1] ?></span>
            </div>
        </div>

        <!-- Matrícula activa -->
        <?php if ($matricula): ?>
        <div class="portal-card">
            <h3 class="portal-card-title"><i class="fa-solid fa-school" style="color:#0EA5E9"></i> Matrícula actual</h3>
            <div style="display:flex;flex-direction:column;gap:.5rem;font-size:.85rem">
                <?php
                $infoMatricula = [
                    'Turma'       => $matricula['turma'] ?? '',
                    'Nível'       => $matricula['nivel'] ?? '',
                    'Turno'       => $matricula['turno'] ?? '',
                    'Ano lectivo' => $matricula['ano_lectivo'] ?? '',
                    'Número'      => $matricula['numero'] ?? '',
                    'Situação'    => ucfirst($matricula['status'] ?? ''),
                ];
                foreach ($infoMatricula as $label => $val): if (empty($val)) continue; ?>
                <div style="display:flex;justify-content:space-between;border-bottom:1px solid #F0F9FF;padding-bottom:.4rem">
                    <span style="color:#64748B"><?= $label ?></span>
                    <span style="font-weight:600;color:#0C4A6E"><?= htmlspecialchars($val) ?></span>
                </div>
                <?php endforeach; ?>
            </div>
        </div>
        <?php endif; ?>

    </div>

    <!-- Coluna direita: dados pessoais + encarregados -->
    <div style="display:flex;flex-direction:column;gap:1rem">

        <!-- Dados pessoais -->
        <div class="portal-card">
            <h3 class="portal-card-title"><i class="fa-solid fa-user" style="color:#0EA5E9"></i> Dados pessoais</h3>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:.6rem .75rem;font-size:.875rem">
                <?php
                $campos = [
                    'Data de nascimento' => !empty($me['data_nascimento']) ? date('d/m/Y', strtotime($me['data_nascimento'])) : '',
                    'Género'             => $me['genero'] ?? '',
                    'Tipo documento'     => $me['documento_tipo'] ?? '',
                    'Nº documento'       => $me['documento_numero'] ?? '',
                    'NUIT'               => $me['nuit'] ?? '',
                    'Telefone'           => $me['telefone'] ?? '',
                    'Email pessoal'      => $me['email'] ?? '',
                    'Email do portal'    => $me['portal_email'] ?? '',
                    'Endereço'           => $me['endereco'] ?? '',
                ];
                foreach ($campos as $label => $val):
                    if (empty($val)) continue;
                    $span = ($label === 'Endereço') ? 'grid-column:1/-1' : '';
                ?>
                <div style="<?= $span ?>">
                    <div style="font-size:.72rem;font-weight:700;text-transform:uppercase;letter-spacing:.04em;color:#94A3B8;margin-bottom:.15rem"><?= $label ?></div>
                    <div style="color:#0C4A6E;font-weight:500"><?= htmlspecialchars($val) ?></div>
                </div>
                <?php endforeach; ?>
            </div>
        </div>

        <!-- Encarregados de educação -->
        <?php if (!empty($encarregados)): ?>
        <div class="portal-card">
            <h3 class="portal-card-title"><i class="fa-solid fa-users" style="color:#0EA5E9"></i> Encarregados de educação</h3>
            <div style="display:flex;flex-direction:column;gap:.75rem">
            <?php foreach ($encarregados as $enc): ?>
            <div style="padding:.85rem;background:#F8FAFC;border-radius:10px;border:1px solid #E0F2FE;display:flex;align-items:flex-start;gap:.85rem">
                <div style="width:40px;height:40px;border-radius:50%;background:#0369A1;display:flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:.95rem;flex-shrink:0">
                    <?= mb_strtoupper(mb_substr($enc['nome'] ?? 'E', 0, 1)) ?>
                </div>
                <div style="flex:1;min-width:0">
                    <div style="font-weight:700;font-size:.9rem;color:#0C4A6E;display:flex;align-items:center;gap:.5rem">
                        <?= htmlspecialchars($enc['nome'] ?? '') ?>
                        <?php if ($enc['principal'] ?? false): ?>
                        <span class="portal-badge badge-blue" style="font-size:.68rem">Principal</span>
                        <?php endif; ?>
                    </div>
                    <div style="font-size:.8rem;color:#64748B;margin-top:.15rem"><?= htmlspecialchars($enc['parentesco'] ?? '') ?></div>
                    <div style="display:flex;gap:1rem;margin-top:.4rem;flex-wrap:wrap">
                        <?php if (!empty($enc['telefone'])): ?>
                        <a href="tel:<?= htmlspecialchars($enc['telefone']) ?>" style="font-size:.8rem;color:#0EA5E9;text-decoration:none">
                            <i class="fa-solid fa-phone" style="font-size:.73rem"></i> <?= htmlspecialchars($enc['telefone']) ?>
                        </a>
                        <?php endif; ?>
                        <?php if (!empty($enc['email'])): ?>
                        <a href="mailto:<?= htmlspecialchars($enc['email']) ?>" style="font-size:.8rem;color:#0EA5E9;text-decoration:none">
                            <i class="fa-solid fa-envelope" style="font-size:.73rem"></i> <?= htmlspecialchars($enc['email']) ?>
                        </a>
                        <?php endif; ?>
                    </div>
                    <?php if (!empty($enc['autorizado_recolher'])): ?>
                    <div style="font-size:.75rem;color:#22C55E;margin-top:.3rem">
                        <i class="fa-solid fa-circle-check" style="font-size:.7rem"></i> Autorizado a recolher o aluno
                    </div>
                    <?php endif; ?>
                </div>
            </div>
            <?php endforeach; ?>
            </div>
        </div>
        <?php endif; ?>

    </div>
</div>

<?php include dirname(__FILE__) . '/layout_bottom.php'; ?>
