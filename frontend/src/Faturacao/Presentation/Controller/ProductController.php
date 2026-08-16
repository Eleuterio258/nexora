<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Presentation\Controller;

use E258Tech\Faturacao\Application\Presenter\ProductListPresenterInterface;
use E258Tech\Faturacao\Application\UseCase\ListProductsUseCase;

final class ProductController
{
    public function __construct(
        private ListProductsUseCase $useCase,
        private ProductListPresenterInterface $presenter
    ) {
    }

    public function __invoke(): void
    {
        $products = $this->useCase->execute();
        echo $this->presenter->present($products);
    }
}
