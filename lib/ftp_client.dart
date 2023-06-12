import 'dart:io';

import 'package:pure_ftp/pure_ftp.dart';
import 'package:pure_ftp/src/file_system/entries/ftp_link.dart';
import 'package:pure_ftp/src/file_system/ftp_file_system.dart';
import 'package:pure_ftp/src/ftp/ftp_socket.dart';
import 'package:yaml/yaml.dart';

class FtpClient {
  final String configFile;

  FtpClient(this.configFile);

  Future<void> connect() async {
    final configFile = File(this.configFile);
    if (!configFile.existsSync()) {
      print('Configuration file not found: $configFile');
      return;
    }

    final config = loadYaml(await configFile.readAsString());
    final ftpSocket = FtpSocket(
      host: config['host'],
      port: config['port'],
      timeout: const Duration(seconds: 30),
      log: print,
    );
    try {
      await ftpSocket.connect(config['username'], config['password'],
          account: config['account']);

      print('Connected');

      final fs = FtpFileSystem(socket: ftpSocket);
      await fs.init();

      final directoryNames = await fs.listDirectoryNames();
      print('Directory Names:');
      print(directoryNames);

      await _getDirList(fs);

      try {
        fs.listType = ListType.MLSD;
        await _getDirList(fs);
      } catch (e) {
        print(e);
      }
    } catch (e) {
      print('Error connecting to FTP server: $e');
    } finally {
      await ftpSocket.disconnect();
    }
  }

  Future<void> _getDirList(FtpFileSystem fs) async {
    final list = await fs.listDirectory();
    list.forEach(print);
    for (final entry in list) {
      if (entry is FtpLink) {
        print('LinkTarget: ${entry.path} -> ${await entry.linkTarget}');
      }
    }
  }
}

void main() async {
  final ftpClient = FtpClient('test_connection2.yml');
  await ftpClient.connect();
}
