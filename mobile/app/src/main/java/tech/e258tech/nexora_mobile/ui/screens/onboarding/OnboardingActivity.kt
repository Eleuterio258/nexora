package tech.e258tech.nexora_mobile.ui.screens.onboarding

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.RecyclerView
import androidx.viewpager2.widget.ViewPager2
import tech.e258tech.nexora_mobile.R
import tech.e258tech.nexora_mobile.databinding.ActivityOnboardingBinding
import tech.e258tech.nexora_mobile.databinding.ItemOnboardingPageBinding
import androidx.core.content.edit
import tech.e258tech.nexora_mobile.ui.screens.login.LoginActivity

class OnboardingActivity : AppCompatActivity() {

    private lateinit var binding: ActivityOnboardingBinding

    private val pages = listOf(
        OnboardingPage(
            title = "Gira o Seu Negocio",
            description = "Solucao ERP completa para empresas mocambicanas. Controle vendas, inventario e financas num so lugar.",
            iconRes = R.drawable.onboarding_erp
        ),
        OnboardingPage(
            title = "Informacao em Tempo Real",
            description = "Dashboards e relatorios poderosos dao-lhe visibilidade imediata sobre cada aspeto das suas operacoes.",
            iconRes = R.drawable.onboarding_analytics
        ),
        OnboardingPage(
            title = "Colabore e Cresça",
            description = "Suporte multi-utilizador e multi-filial com controlo de acessos por perfil. Cresça com confiança.",
            iconRes = R.drawable.onboarding_team
        ),
        OnboardingPage(
            title = "Feito para Mocambique",
            description = "Suporte nativo a MZN, M-Pesa, e-Mola, NUIT e legislacao fiscal local — pronto para o seu mercado.",
            iconRes = R.drawable.onboarding_mozambique
        )
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityOnboardingBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.viewPager.adapter = OnboardingAdapter(pages)

        binding.viewPager.registerOnPageChangeCallback(object : ViewPager2.OnPageChangeCallback() {
            override fun onPageSelected(position: Int) {
                updateIndicators(position)
                binding.btnNext.text = if (position == pages.lastIndex) "Comecar" else "Seguinte"
                binding.tvSkip.visibility = if (position == pages.lastIndex) View.INVISIBLE else View.VISIBLE
            }
        })

        binding.btnNext.setOnClickListener {
            if (binding.viewPager.currentItem < pages.lastIndex) {
                binding.viewPager.currentItem++
            } else {
                finishOnboarding()
            }
        }

        binding.tvSkip.setOnClickListener { finishOnboarding() }
    }

    private fun updateIndicators(active: Int) {
        val indicators = listOf(binding.indicator0, binding.indicator1, binding.indicator2, binding.indicator3)
        indicators.forEachIndexed { index, view ->
            if (index == active) {
                view.layoutParams.width = resources.getDimensionPixelSize(R.dimen.indicator_active_width)
                view.setBackgroundResource(R.drawable.bg_indicator_active)
            } else {
                view.layoutParams.width = resources.getDimensionPixelSize(R.dimen.indicator_inactive_size)
                view.setBackgroundResource(R.drawable.bg_indicator_inactive)
            }
            view.requestLayout()
        }
    }

    private fun finishOnboarding() {
        getSharedPreferences("nexora_prefs", Context.MODE_PRIVATE)
            .edit { putBoolean("onboarding_complete", true) }
        startActivity(Intent(this, LoginActivity::class.java))
        overridePendingTransition(android.R.anim.slide_in_left, android.R.anim.slide_out_right)
        finish()
    }
}

data class OnboardingPage(
    val title: String,
    val description: String,
    val iconRes: Int
)

class OnboardingAdapter(private val pages: List<OnboardingPage>) :
    RecyclerView.Adapter<OnboardingAdapter.PageViewHolder>() {

    inner class PageViewHolder(val binding: ItemOnboardingPageBinding) :
        RecyclerView.ViewHolder(binding.root)

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): PageViewHolder {
        val binding = ItemOnboardingPageBinding.inflate(
            LayoutInflater.from(parent.context), parent, false
        )
        return PageViewHolder(binding)
    }

    override fun onBindViewHolder(holder: PageViewHolder, position: Int) {
        val page = pages[position]
        with(holder.binding) {
            tvTitle.text = page.title
            tvDescription.text = page.description
            ivIllustration.setImageResource(page.iconRes)
            ivIllustration.clearColorFilter()
        }
    }

    override fun getItemCount() = pages.size
}
