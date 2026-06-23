<!DOCTYPE html>
<html lang="pt">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description"
        content="E258Tech - Soluções Digitais Inovadoras. Transformamos ideias em soluções digitais de excelência em Moçambique.">
    <title>E258Tech - Soluções Digitais Inovadoras</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link
        href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700&family=Fira+Code:wght@400;500&display=swap"
        rel="stylesheet">
    <link rel="stylesheet" href="/assets/css/styles.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css" crossorigin="anonymous" referrerpolicy="no-referrer">
</head>

<body>

    <?php include 'src/View/templates/partials/nav.php'; ?>

    <!-- Hero Section -->
    <section class="hero">
        <div class="container hero-container">
            <div class="hero-content">
                <h1 class="hero-title">
                    Soluções Digitais <span class="text-green">Inovadoras</span>
                </h1>
                <p class="hero-subtitle">Transformamos ideias em soluções digitais de excelência</p>
                <p class="hero-description">
                    A e258tech desenvolve software personalizado de alta qualidade para impulsionar o crescimento da sua
                    empresa através da tecnologia e inovação.
                </p>
                <div class="hero-cta">
                    <a href="https://wa.me/258870755700?text=Olá,%20gostaria%20de%20falar%20com%20a%20E258Tech"
                        class="btn-primary btn-lg">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                            <path
                                d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z" />
                        </svg>
                        Fale Connosco
                    </a>
                    <a href="#servicos" class="btn-secondary btn-lg">
                        Conheça os Nossos Serviços
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                            stroke-width="2">
                            <polyline points="9 18 15 12 9 6"></polyline>
                        </svg>
                    </a>
                </div>
                <div class="hero-tech-tags">
                    <span class="hero-tech-label">Tecnologias que dominamos:</span>
                    <div class="hero-tags-row">
                        <span class="tech-tag"><img src="/assets/images/icons/react.svg" class="tag-icon" alt=""> React</span>
                        <span class="tech-tag"><img src="/assets/images/icons/flutter.svg" class="tag-icon" alt=""> Flutter</span>
                        <span class="tech-tag"><img src="/assets/images/icons/nodedotjs.svg" class="tag-icon" alt=""> Node.js</span>
                        <span class="tech-tag"><img src="/assets/images/icons/postgresql.svg" class="tag-icon" alt=""> PostgreSQL</span>
                    </div>
                </div>
            </div>
            <div class="hero-image">
                <div class="code-window">
                    <div class="code-window-header">
                        <span class="dot dot-red"></span>
                        <span class="dot dot-yellow"></span>
                        <span class="dot dot-green"></span>
                        <span class="code-window-title">e258tech.ts</span>
                    </div>
                    <pre class="code-block"><code><span class="code-keyword">interface</span> <span class="code-type">Solution</span> {
  <span class="code-property">transform</span>(<span class="code-variable">idea</span>: <span class="code-type">string</span>)
  <span class="code-keyword">return</span> <span class="code-variable">e258tech</span>.<span class="code-property">build</span>(<span class="code-variable">idea</span>)
}</code></pre>
                </div>
            </div>
        </div>
    </section>

    <!-- Serviços Section -->
    <section id="servicos" class="section" style="padding-top:1rem; padding-bottom:1rem;">
        <div class="container">
            <div class="section-header-row">
                <div>
                    <h2 class="section-title" style="text-align:left;margin-bottom:0.5rem;">Nossos Serviços</h2>
                    <p class="section-subtitle" style="text-align:left;margin:0;">Oferecemos soluções completas em Tecnologia, Ordenamento Territorial, Ambiente e Geotecnologia.</p>
                </div>
                <div class="carousel-nav">
                    <button class="carousel-btn" id="prevBtn" aria-label="Anterior">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="15 18 9 12 15 6"/></svg>
                    </button>
                    <button class="carousel-btn" id="nextBtn" aria-label="Seguinte">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="9 18 15 12 9 6"/></svg>
                    </button>
                </div>
            </div>

            <div class="carousel-wrapper">
                <div class="carousel-track" id="carouselTrack">

                    <div class="carousel-slide">
                        <div class="service-icon-wrap green"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg></div>
                        <h3 class="slide-title">Desenvolvimento Web e Mobile</h3>
                        <p class="slide-desc">Criação de aplicações web e móveis desde a fase inicial até à implementação, utilizando frameworks como React, Flutter e Node.js.</p>
                        <div class="service-tags"><span class="service-tag">React &amp; Next.js</span><span class="service-tag">Flutter</span><span class="service-tag">Node.js</span></div>
                    </div>

                    <div class="carousel-slide">
                        <div class="service-icon-wrap yellow"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg></div>
                        <h3 class="slide-title">Soluções em Nuvem</h3>
                        <p class="slide-desc">Implementação de infraestruturas em nuvem, com especialização em AWS, Google Cloud e Linode.</p>
                        <div class="service-tags"><span class="service-tag">AWS</span><span class="service-tag">Google Cloud</span><span class="service-tag">Linode</span></div>
                    </div>

                    <div class="carousel-slide">
                        <div class="service-icon-wrap green"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 20V10"/><path d="M12 20V4"/><path d="M6 20v-6"/></svg></div>
                        <h3 class="slide-title">Integração de APIs</h3>
                        <p class="slide-desc">Desenvolvimento de APIs seguras e escaláveis para integração de sistemas.</p>
                        <div class="service-tags"><span class="service-tag">REST APIs</span><span class="service-tag">GraphQL</span><span class="service-tag">gRPC</span></div>
                    </div>

                    <div class="carousel-slide">
                        <div class="service-icon-wrap yellow"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/></svg></div>
                        <h3 class="slide-title">Sistemas Personalizados</h3>
                        <p class="slide-desc">Desenvolvimento de software à medida para automatizar processos empresariais.</p>
                        <div class="service-tags"><span class="service-tag">ERP</span><span class="service-tag">CRM</span><span class="service-tag">Automação</span></div>
                    </div>

                    <div class="carousel-slide">
                        <div class="service-icon-wrap green"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg></div>
                        <h3 class="slide-title">Manutenção e Suporte</h3>
                        <p class="slide-desc">Prestação de suporte contínuo e melhorias para garantir a performance ideal das soluções tecnológicas.</p>
                        <div class="service-tags"><span class="service-tag">24/7 Suporte</span><span class="service-tag">Monitoramento</span><span class="service-tag">Otimização</span></div>
                    </div>

                    <div class="carousel-slide">
                        <div class="service-icon-wrap yellow"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg></div>
                        <h3 class="slide-title">Inteligência Artificial</h3>
                        <p class="slide-desc">Criação de soluções inteligentes com machine learning, processamento de linguagem natural e análise preditiva.</p>
                        <div class="service-tags"><span class="service-tag">Machine Learning</span><span class="service-tag">NLP</span><span class="service-tag">Computer Vision</span></div>
                    </div>

                    <div class="carousel-slide">
                        <div class="service-icon-wrap green"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 6v16l7-4 8 4 7-4V2l-7 4-8-4-7 4z"/><line x1="8" y1="2" x2="8" y2="18"/><line x1="16" y1="6" x2="16" y2="22"/></svg></div>
                        <h3 class="slide-title">Sistemas GIS</h3>
                        <p class="slide-desc">Trabalhamos com sistemas de informação geográfica, oferecendo serviços especializados em ArcGIS, QGIS, AutoCAD e GeoServer.</p>
                        <div class="service-tags"><span class="service-tag">ArcGIS</span><span class="service-tag">QGIS</span><span class="service-tag">GeoServer</span></div>
                    </div>

                    <div class="carousel-slide">
                        <div class="service-icon-wrap yellow"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/></svg></div>
                        <h3 class="slide-title">Ordenamento Territorial</h3>
                        <p class="slide-desc">Soluções para planeamento urbano, zoneamento e gestão territorial usando ferramentas GIS avançadas.</p>
                        <div class="service-tags"><span class="service-tag">Planeamento Urbano</span><span class="service-tag">Zoneamento</span></div>
                    </div>

                    <div class="carousel-slide">
                        <div class="service-icon-wrap green"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg></div>
                        <h3 class="slide-title">Gestão Ambiental</h3>
                        <p class="slide-desc">Sistemas de monitoramento ambiental, avaliação de impacto e soluções sustentáveis para projetos diversos.</p>
                        <div class="service-tags"><span class="service-tag">Monitoramento</span><span class="service-tag">Impacto Ambiental</span></div>
                    </div>

                </div><!-- /carousel-track -->
            </div><!-- /carousel-wrapper -->

            <div class="carousel-dots" id="carouselDots"></div>

        </div>
    </section>

    <!-- Tecnologias Section -->
    <section id="tecnologias" class="section" style="padding-top:1rem; padding-bottom:1rem;">
        <div class="container">
            <div class="section-header">
                <h2 class="section-title">Tecnologias</h2>
                <p class="section-subtitle">Nossa expertise abrange um amplo espectro de tecnologias modernas,
                    garantindo soluções robustas e escaláveis para cada projeto.</p>
            </div>

            <!-- Tab Buttons -->
            <div class="tech-tabs">
                <button class="tech-tab-btn active" data-tab="frontend">Frontend</button>
                <button class="tech-tab-btn" data-tab="backend">Backend</button>
                <button class="tech-tab-btn" data-tab="mobile">Mobile</button>
                <button class="tech-tab-btn" data-tab="database">Database</button>
                <button class="tech-tab-btn" data-tab="cloud">Cloud &amp; DevOps</button>
                <button class="tech-tab-btn" data-tab="ai">AI &amp; ML</button>
                <button class="tech-tab-btn" data-tab="gis">GIS</button>
            </div>

            <!-- Tab Panels -->
            <div class="tech-panel active" id="tab-frontend">
                <div class="tech-panel-header">
                    <h3 class="tech-panel-title">Frontend Development</h3>
                    <p class="tech-panel-desc">Frameworks e bibliotecas para desenvolvimento de interfaces modernas e
                        responsivas</p>
                </div>
                <div class="tech-items-grid">
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/react.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">React</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/nextdotjs.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">Next.js</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/vuedotjs.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">Vue.js</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/angular.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">Angular</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/typescript.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">TypeScript</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/tailwindcss.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">Tailwind CSS</span>
                        </div>
                    </div>
                </div>
            </div>

            <div class="tech-panel" id="tab-backend">
                <div class="tech-panel-header">
                    <h3 class="tech-panel-title">Backend Development</h3>
                    <p class="tech-panel-desc">Tecnologias para construção de APIs robustas, escaláveis e de alta
                        performance</p>
                </div>
                <div class="tech-items-grid">
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/nodedotjs.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">Node.js</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/python.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">Python (Django)</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/php.svg" class="tech-icon"
                                alt="PHP"><span class="tech-item-name">PHP (Laravel)</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/openjdk.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">Java (Spring)</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/dotnet.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">.NET Core</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/postman.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">REST APIs</span></div>
                    </div>
                </div>
            </div>

            <div class="tech-panel" id="tab-mobile">
                <div class="tech-panel-header">
                    <h3 class="tech-panel-title">Mobile Development</h3>
                    <p class="tech-panel-desc">Frameworks para criação de aplicações móveis nativas e multiplataforma
                    </p>
                </div>
                <div class="tech-items-grid">
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/flutter.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">Flutter</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/react.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">React Native</span>
                        </div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/swift.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">Swift</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/kotlin.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">Kotlin</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/ionic.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">Ionic</span></div>
                    </div>
                </div>
            </div>

            <div class="tech-panel" id="tab-database">
                <div class="tech-panel-header">
                    <h3 class="tech-panel-title">Database Systems</h3>
                    <p class="tech-panel-desc">Sistemas de bases de dados relacionais e não relacionais para
                        armazenamento seguro e eficiente</p>
                </div>
                <div class="tech-items-grid">
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/postgresql.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">PostgreSQL</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/mongodb.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">MongoDB</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/mysql.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">MySQL</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/redis.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">Redis</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/postgresql.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">PostGIS</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/oracle.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">Oracle</span></div>
                    </div>
                </div>
            </div>

            <div class="tech-panel" id="tab-cloud">
                <div class="tech-panel-header">
                    <h3 class="tech-panel-title">Cloud &amp; DevOps</h3>
                    <p class="tech-panel-desc">Plataformas de nuvem e ferramentas de automação para infraestruturas
                        escaláveis</p>
                </div>
                <div class="tech-items-grid">
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/aws.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">AWS</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/docker.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">Docker</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/kubernetes.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">Kubernetes</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/googlecloud.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">Google Cloud</span>
                        </div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/azure.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">Azure</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/githubactions.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">CI/CD</span></div>
                    </div>
                </div>
            </div>

            <div class="tech-panel" id="tab-ai">
                <div class="tech-panel-header">
                    <h3 class="tech-panel-title">AI &amp; Machine Learning</h3>
                    <p class="tech-panel-desc">Bibliotecas e frameworks para desenvolvimento de soluções inteligentes e
                        modelos preditivos</p>
                </div>
                <div class="tech-items-grid">
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/tensorflow.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">TensorFlow</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/pytorch.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">PyTorch</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/scikitlearn.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">Scikit-learn</span>
                        </div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/opencv.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">OpenCV</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/python.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">NLP</span></div>
                    </div>
                </div>
            </div>

            <div class="tech-panel" id="tab-gis">
                <div class="tech-panel-header">
                    <h3 class="tech-panel-title">Geographic Information Systems</h3>
                    <p class="tech-panel-desc">Ferramentas especializadas para análise espacial, mapeamento e gestão de
                        dados geográficos</p>
                </div>
                <div class="tech-items-grid">
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/postgresql.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">PostGIS</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/qgis.svg" class="tech-icon"
                                alt="QGIS"><span class="tech-item-name">QGIS</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/esri.svg" class="tech-icon"
                                alt="ArcGIS"><span class="tech-item-name">ArcGIS</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/leaflet.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">Leaflet</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/mapbox.svg"
                                class="tech-icon" alt=""><span class="tech-item-name">Mapbox</span></div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-item-left"><img src="/assets/images/icons/geoserver.png"
                                class="tech-icon" alt=""><span
                                class="tech-item-name">GeoServer</span></div>
                    </div>
                </div>
            </div>

        </div>
    </section>

    <!-- Sobre Section -->
    <section id="sobre" class="section bg-light" style="padding-top:1rem; padding-bottom:1rem;">
        <div class="container">
            <div class="about-layout">
                <div class="about-intro">
                    <h2 class="section-title" style="text-align:left; margin-bottom:1rem;">Sobre a e258tech</h2>
                    <p class="about-lead">A e258tech é uma empresa inovadora de desenvolvimento de software,
                        especializada na criação de soluções tecnológicas personalizadas para diferentes indústrias. Com
                        sede em Bagamoyo, a nossa missão é transformar ideias em produtos digitais de alta qualidade.
                    </p>
                    <div class="about-mv">
                        <div class="about-mv-item">
                            <span class="about-mv-label">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                                    stroke-width="2">
                                    <circle cx="12" cy="12" r="10" />
                                    <circle cx="12" cy="12" r="3" />
                                </svg>
                                Missão
                            </span>
                            <p class="about-mv-text">Desenvolver soluções tecnológicas de excelência que capacitem as
                                empresas a alcançar o máximo potencial, através de software de alta qualidade e serviços
                                focados nos resultados e na inovação.</p>
                        </div>
                        <div class="about-mv-item">
                            <span class="about-mv-label">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                                    stroke-width="2">
                                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                                    <circle cx="12" cy="12" r="3" />
                                </svg>
                                Visão
                            </span>
                            <p class="about-mv-text">Ser reconhecida como uma referência global em desenvolvimento de
                                software e inovação tecnológica, oferecendo produtos que transformem os sectores em que
                                atuamos.</p>
                        </div>
                    </div>
                </div>
                <div class="about-values">
                    <h3 class="about-values-title">Os Nossos Valores</h3>
                    <ul class="values-list">
                        <li class="value-item">
                            <span class="value-icon" style="background:#ecfdf5; color:#10b981;">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                                    stroke-width="2">
                                    <circle cx="12" cy="12" r="10" />
                                    <line x1="12" y1="8" x2="12" y2="12" />
                                    <line x1="12" y1="16" x2="12.01" y2="16" />
                                </svg>
                            </span>
                            <div>
                                <strong>Inovação</strong>
                                <p>Incentivamos a criatividade para entregar soluções que superem as expectativas.</p>
                            </div>
                        </li>
                        <li class="value-item">
                            <span class="value-icon" style="background:#ecfdf5; color:#10b981;">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                                    stroke-width="2">
                                    <polyline points="20 6 9 17 4 12" />
                                </svg>
                            </span>
                            <div>
                                <strong>Qualidade</strong>
                                <p>Mantemos elevados padrões de excelência em todas as fases do processo de
                                    desenvolvimento.</p>
                            </div>
                        </li>
                        <li class="value-item">
                            <span class="value-icon" style="background:#ecfdf5; color:#10b981;">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                                    stroke-width="2">
                                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                                    <circle cx="9" cy="7" r="4" />
                                    <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
                                    <path d="M16 3.13a4 4 0 0 1 0 7.75" />
                                </svg>
                            </span>
                            <div>
                                <strong>Colaboração</strong>
                                <p>Trabalhamos de forma próxima com os nossos clientes para garantir que as suas visões
                                    se tornem realidade.</p>
                            </div>
                        </li>
                        <li class="value-item">
                            <span class="value-icon" style="background:#ecfdf5; color:#10b981;">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                                    stroke-width="2">
                                    <circle cx="12" cy="12" r="10" />
                                    <polyline points="12 6 12 12 16 14" />
                                </svg>
                            </span>
                            <div>
                                <strong>Agilidade</strong>
                                <p>Adaptamo-nos rapidamente às mudanças do mercado e às necessidades dos clientes, com
                                    foco na entrega eficaz.</p>
                            </div>
                        </li>
                    </ul>
                </div>
            </div>
        </div>
    </section>

    <!-- Contato Section -->
    <section id="contato" class="section" style="padding-top:1rem;">
        <div class="container">
            <div class="contact-layout">
                <div class="contact-left">
                    <h2 class="section-title" style="text-align:left; margin-bottom:0.75rem;">Entre em Contacto</h2>
                    <p class="about-lead" style="margin-bottom:2.5rem;">Estamos prontos para ouvir sobre o seu projecto
                        e como podemos ajudar a torná-lo realidade.</p>
                    <div class="contact-info-list">
                        <div class="contact-info-item">
                            <div class="contact-info-icon">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                                    stroke-width="2">
                                    <path
                                        d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
                                    <polyline points="22,6 12,13 2,6" />
                                </svg>
                            </div>
                            <div>
                                <p class="contact-info-label">Email</p>
                                <a href="mailto:e258tech@gmail.com" class="contact-link">e258tech@gmail.com</a>
                            </div>
                        </div>
                        <div class="contact-info-item">
                            <div class="contact-info-icon">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                                    stroke-width="2">
                                    <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
                                    <circle cx="12" cy="10" r="3" />
                                </svg>
                            </div>
                            <div>
                                <p class="contact-info-label">Endereço</p>
                                <p class="contact-link">Bairro Bagamoyo, Moçambique</p>
                            </div>
                        </div>
                    </div>
                    <div class="hours-box" style="margin-top:2rem;">
                        <h4 class="hours-title">Horário de Funcionamento</h4>
                        <div class="hours-grid">
                            <div class="hours-item">
                                <p class="hours-day">Segunda - Sexta</p>
                                <p class="hours-time">8:00 - 18:00</p>
                            </div>
                            <div class="hours-item">
                                <p class="hours-day">Sábado</p>
                                <p class="hours-time">9:00 - 15:00</p>
                            </div>
                            <div class="hours-item hours-closed">
                                <p class="hours-day">Domingo</p>
                                <p class="hours-time">Fechado</p>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="contact-right">
                    <div class="contact-form-box">
                        <form class="contact-form" id="contactForm">
                            <div class="form-group">
                                <label class="form-label" for="nome">Nome Completo</label>
                                <input type="text" id="nome" name="nome" class="form-input"
                                    placeholder="Seu nome completo" required>
                            </div>
                            <div class="form-group">
                                <label class="form-label" for="email">Email</label>
                                <input type="email" id="email" name="email" class="form-input"
                                    placeholder="seu.email@exemplo.com" required>
                            </div>
                            <div class="form-group">
                                <label class="form-label" for="assunto">Assunto</label>
                                <input type="text" id="assunto" name="assunto" class="form-input"
                                    placeholder="Assunto da mensagem" required>
                            </div>
                            <div class="form-group">
                                <label class="form-label" for="mensagem">Mensagem</label>
                                <textarea id="mensagem" name="mensagem" class="form-textarea" rows="5"
                                    placeholder="Descreva o seu projecto ou dúvida..." required></textarea>
                            </div>
                            <input type="hidden" name="csrf_token" value="<?= $csrf ?>">
                            <button type="submit" class="btn-primary btn-lg form-submit" id="btnContacto">
                                Enviar Mensagem
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <line x1="22" y1="2" x2="11" y2="13"></line>
                                    <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                                </svg>
                            </button>
                            <p class="form-msg" id="formMsg" style="margin-top:.75rem;font-size:.875rem;"></p>
                        </form>
                    </div>
                </div>
            </div>
    </section>

    <!-- Footer -->
    <?php include 'src/View/templates/partials/footer.php'; ?>

    <script src="/assets/js/script.js"></script>
</body>

</html>
