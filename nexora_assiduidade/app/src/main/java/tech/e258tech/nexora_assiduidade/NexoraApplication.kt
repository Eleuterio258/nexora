package tech.e258tech.nexora_assiduidade

import android.app.Application
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient

class NexoraApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        RetrofitClient.init(this)
    }
}
