import * as vscode from 'vscode';
import * as net from 'net';

// Status-bar item shows current pending count from vibeclone socket.
let statusBar: vscode.StatusBarItem;

export function activate(ctx: vscode.ExtensionContext) {
  statusBar = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 100);
  statusBar.text = '$(eye) VibeClone';
  statusBar.tooltip = 'Open VibeClone history';
  statusBar.command = 'vibeclone.openHistory';
  statusBar.show();
  ctx.subscriptions.push(statusBar);

  ctx.subscriptions.push(
    vscode.commands.registerCommand('vibeclone.openHistory', () => {
      vscode.env.openExternal(vscode.Uri.parse('vibeclone://history'));
    }),
    vscode.commands.registerCommand('vibeclone.toggleAutoApprove', async () => {
      await sendCommand({ kind: 'toggle_auto_approve' });
    }),
  );

  // Poll pending count every 3s.
  const tick = setInterval(async () => {
    try {
      const reply = await sendCommand({ kind: 'pending_count' });
      if (typeof reply?.count === 'number') {
        statusBar.text = reply.count > 0
          ? `$(bell-dot) VibeClone ${reply.count}`
          : `$(eye) VibeClone`;
      }
    } catch { /* socket not available */ }
  }, 3000);
  ctx.subscriptions.push({ dispose: () => clearInterval(tick) });
}

export function deactivate() {}

async function sendCommand(payload: any): Promise<any> {
  const path = vscode.workspace.getConfiguration('vibeclone').get<string>('socketPath')
            ?? '/tmp/vibeclone.sock';
  return new Promise((resolve, reject) => {
    const conn = net.createConnection(path);
    const body = Buffer.from(JSON.stringify(payload), 'utf8');
    const header = Buffer.alloc(4);
    header.writeUInt32BE(body.length, 0);
    let buf = Buffer.alloc(0);
    conn.on('data', d => { buf = Buffer.concat([buf, d]); });
    conn.on('end', () => {
      try {
        const len = buf.readUInt32BE(0);
        const obj = JSON.parse(buf.slice(4, 4 + len).toString('utf8'));
        resolve(obj);
      } catch (e) { reject(e); }
    });
    conn.on('error', reject);
    conn.setTimeout(2000, () => { conn.destroy(new Error('timeout')); });
    conn.write(Buffer.concat([header, body]));
  });
}
