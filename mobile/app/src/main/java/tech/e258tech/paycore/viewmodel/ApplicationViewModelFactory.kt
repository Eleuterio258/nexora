package tech.e258tech.paycore.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider

/** Factory mínima para ViewModels construídos a partir de um lambda — não há framework de DI
 * instalado no projecto (ver plano de refactor em fases), por isso esta é a forma mais simples
 * de fugir ao construtor sem-argumentos por omissão do ViewModelProvider. */
class ApplicationViewModelFactory<T : ViewModel>(
    private val creator: () -> T
) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <VM : ViewModel> create(modelClass: Class<VM>): VM = creator() as VM
}
