package tech.e258tech.nexora_mobile.ui.screens.splash

import android.animation.Animator
import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.view.animation.AccelerateDecelerateInterpolator
import android.view.animation.OvershootInterpolator
import androidx.appcompat.app.AppCompatActivity
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.core.view.WindowInsetsControllerCompat
import tech.e258tech.nexora_mobile.R
import tech.e258tech.nexora_mobile.databinding.ActivitySplashBinding
import tech.e258tech.nexora_mobile.ui.screens.login.LoginActivity
import tech.e258tech.nexora_mobile.ui.screens.onboarding.OnboardingActivity

@SuppressLint("CustomSplashScreen")
class SplashActivity : AppCompatActivity() {

    private lateinit var binding: ActivitySplashBinding
    private val runningAnimators = mutableListOf<Animator>()

    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()
        super.onCreate(savedInstanceState)
        setTheme(R.style.Theme_Nexoramobile)
        window.statusBarColor = getColor(R.color.white)
        window.navigationBarColor = getColor(R.color.white)
        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = true
            isAppearanceLightNavigationBars = true
        }
        splashScreen.setOnExitAnimationListener { splashScreenView ->
            val fadeOut = ObjectAnimator.ofFloat(splashScreenView.view, View.ALPHA, 1f, 0f).apply {
                duration = 260
                interpolator = AccelerateDecelerateInterpolator()
            }
            val iconScaleX = ObjectAnimator.ofFloat(splashScreenView.iconView, View.SCALE_X, 1f, 0.86f).apply {
                duration = 260
                interpolator = AccelerateDecelerateInterpolator()
            }
            val iconScaleY = ObjectAnimator.ofFloat(splashScreenView.iconView, View.SCALE_Y, 1f, 0.86f).apply {
                duration = 260
                interpolator = AccelerateDecelerateInterpolator()
            }

            AnimatorSet().apply {
                play(fadeOut).with(iconScaleX).with(iconScaleY)
                addListener(object : android.animation.AnimatorListenerAdapter() {
                    override fun onAnimationEnd(animation: Animator) {
                        splashScreenView.remove()
                    }
                })
                start()
            }
        }

        binding = ActivitySplashBinding.inflate(layoutInflater)
        setContentView(binding.root)

        val logoScaleX = ObjectAnimator.ofFloat(binding.llLogo, View.SCALE_X, 0.3f, 1f).apply {
            duration = 700
            interpolator = OvershootInterpolator(1.5f)
        }
        val logoScaleY = ObjectAnimator.ofFloat(binding.llLogo, View.SCALE_Y, 0.3f, 1f).apply {
            duration = 700
            interpolator = OvershootInterpolator(1.5f)
        }
        val logoFade = ObjectAnimator.ofFloat(binding.llLogo, View.ALPHA, 0f, 1f).apply {
            duration = 500
        }
        val taglineTranslate = ObjectAnimator.ofFloat(binding.tvTagline, View.TRANSLATION_Y, 30f, 0f).apply {
            duration = 500
            interpolator = AccelerateDecelerateInterpolator()
        }
        val taglineFade = ObjectAnimator.ofFloat(binding.tvTagline, View.ALPHA, 0f, 1f).apply {
            duration = 500
        }
        val dotsFade = ObjectAnimator.ofFloat(binding.llDots, View.ALPHA, 0f, 1f).apply {
            duration = 400
        }
        val logoPulseX = ObjectAnimator.ofFloat(binding.ivSplashLogo, View.SCALE_X, 1f, 1.08f, 1f).apply {
            duration = 1200
            repeatCount = ValueAnimator.INFINITE
            interpolator = AccelerateDecelerateInterpolator()
        }
        val logoPulseY = ObjectAnimator.ofFloat(binding.ivSplashLogo, View.SCALE_Y, 1f, 1.08f, 1f).apply {
            duration = 1200
            repeatCount = ValueAnimator.INFINITE
            interpolator = AccelerateDecelerateInterpolator()
        }

        AnimatorSet().apply {
            play(logoScaleX).with(logoScaleY).with(logoFade)
            play(taglineTranslate).with(taglineFade).after(logoFade)
            play(dotsFade).after(taglineFade)
            addListener(object : android.animation.AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    startLoadingAnimation()
                    logoPulseX.start()
                    logoPulseY.start()
                    runningAnimators.add(logoPulseX)
                    runningAnimators.add(logoPulseY)
                }
            })
            start()
        }

        binding.root.postDelayed({ navigateNext() }, 2800)
    }

    private fun startLoadingAnimation() {
        listOf(binding.dot1, binding.dot2, binding.dot3).forEachIndexed { index, dot ->
            val bounce = ObjectAnimator.ofFloat(dot, View.TRANSLATION_Y, 0f, -10f, 0f).apply {
                duration = 650
                startDelay = (index * 130).toLong()
                repeatCount = ValueAnimator.INFINITE
                interpolator = AccelerateDecelerateInterpolator()
            }
            val fade = ObjectAnimator.ofFloat(dot, View.ALPHA, 0.45f, 1f, 0.45f).apply {
                duration = 650
                startDelay = (index * 130).toLong()
                repeatCount = ValueAnimator.INFINITE
                interpolator = AccelerateDecelerateInterpolator()
            }
            bounce.start()
            fade.start()
            runningAnimators.add(bounce)
            runningAnimators.add(fade)
        }
    }

    private fun navigateNext() {
        val prefs = getSharedPreferences("nexora_prefs", Context.MODE_PRIVATE)
        val onboardingDone = prefs.getBoolean("onboarding_complete", false)
        val target = if (onboardingDone) LoginActivity::class.java else OnboardingActivity::class.java
        startActivity(Intent(this, target))
        overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out)
        finish()
    }

    override fun onDestroy() {
        runningAnimators.forEach { it.cancel() }
        runningAnimators.clear()
        super.onDestroy()
    }
}
