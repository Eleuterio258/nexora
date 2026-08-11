<?php

declare(strict_types=1);

namespace PHC\Presentation\Controller;

use PHC\Application\Presenter\ProductListPresenterInterface;
use PHC\Application\UseCase\ListProductsUseCase;

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
