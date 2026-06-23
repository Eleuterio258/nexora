<?php
// $activePage = 'home' | 'vagas'
$activePage = $activePage ?? 'home';

$navVagasAbertas = $app->openVacancies->count();
?>
<nav class="nav">
    <div class="container nav-container">
        <a href="/" class="logo">
            <img src="/assets/images/e258tech-logo.png" alt="E258Tech" class="logo-img">
        </a>
        <button class="mobile-menu-btn" id="mobileMenuBtn" aria-label="Menu">
            <span></span><span></span><span></span>
        </button>
        <ul class="nav-menu" id="navMenu">
            <?php if ($activePage === 'home' || $activePage === 'carreira'): ?>
            <?php if ($activePage === 'home'): ?>
            <li><a href="#servicos"    class="nav-link">Serviços</a></li>
            <li><a href="#tecnologias" class="nav-link">Tecnologias</a></li>
            <li><a href="#sobre"       class="nav-link">Sobre Nós</a></li>
            <li><a href="#contato"     class="nav-link">Contato</a></li>
            <?php if ($navVagasAbertas > 0): ?>
            <li><a href="/vagas" class="nav-link">Carreira Profissional</a></li>
            <?php endif; ?>
            <?php else: ?>
            <li><a href="/" class="nav-link" data-section="servicos">Serviços</a></li>
            <li><a href="/" class="nav-link" data-section="tecnologias">Tecnologias</a></li>
            <li><a href="/" class="nav-link" data-section="sobre">Sobre Nós</a></li>
            <?php if ($navVagasAbertas > 0): ?>
            <li><a href="/vagas" class="nav-link nav-link--active">Carreira Profissional</a></li>
            <?php endif; ?>
            <li><a href="/" class="nav-link" data-section="contato">Contato</a></li>
            <?php endif; ?>
            <li><a href="https://wa.me/258870755700?text=Olá,%20gostaria%20de%20falar%20com%20a%20E258Tech" class="btn-primary">Fale Connosco</a></li>
            <?php else: ?>
            <li>
                <a href="/" class="nav-link nav-back">
                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="19" y1="12" x2="5" y2="12"/>
                        <polyline points="12 19 5 12 12 5"/>
                    </svg>
                    e258tech.tech
                </a>
            </li>
            <?php endif; ?>
        </ul>
    </div>
</nav>
<script>
document.querySelectorAll('a[data-section]').forEach(function(link) {
    link.addEventListener('click', function(e) {
        e.preventDefault();
        sessionStorage.setItem('scrollTo', this.dataset.section);
        window.location.href = this.href;
    });
});
</script>
