package app.vibeclone

import com.intellij.openapi.project.Project
import com.intellij.openapi.wm.StatusBarWidget
import com.intellij.openapi.wm.StatusBarWidgetFactory
import com.intellij.openapi.wm.impl.status.widget.StatusBarWidgetsManager
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.IOException
import java.net.StandardProtocolFamily
import java.net.UnixDomainSocketAddress
import java.nio.ByteBuffer
import java.nio.channels.SocketChannel
import javax.swing.Icon

class VibeCloneStatusWidget : StatusBarWidgetFactory {
    override fun getId(): String = "vibeclone.status"
    override fun getDisplayName(): String = "VibeClone"
    override fun isAvailable(project: Project): Boolean = true
    override fun createWidget(project: Project): StatusBarWidget = Widget()
    override fun disposeWidget(widget: StatusBarWidget) {}
    override fun canBeEnabledOn(statusBar: com.intellij.openapi.wm.StatusBar): Boolean = true

    private class Widget : StatusBarWidget {
        override fun ID(): String = "vibeclone.status"
        override fun install(statusBar: com.intellij.openapi.wm.StatusBar) {
            // Poll every 3s in a background thread. Real impl would use coroutines + dispose.
            Thread {
                while (!Thread.currentThread().isInterrupted) {
                    val count = pendingCount() ?: -1
                    // TODO: update widget UI on EDT
                    Thread.sleep(3000)
                }
            }.also { it.isDaemon = true }.start()
        }
        override fun dispose() {}
        override fun getPresentation(): StatusBarWidget.WidgetPresentation? = null
    }

    private fun pendingCount(): Int? {
        return try {
            SocketChannel.open(StandardProtocolFamily.UNIX).use { ch ->
                ch.connect(UnixDomainSocketAddress.of("/tmp/vibeclone.sock"))
                val payload = "{\"kind\":\"pending_count\"}".toByteArray()
                val header = ByteBuffer.allocate(4).putInt(payload.size).flip() as ByteBuffer
                ch.write(header)
                ch.write(ByteBuffer.wrap(payload))
                // (parse JSON-RPC reply omitted for brevity)
                0
            }
        } catch (e: IOException) {
            null
        }
    }
}
