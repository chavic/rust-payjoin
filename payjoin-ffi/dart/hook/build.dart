import 'package:hooks/hooks.dart';
import 'package:native_toolchain_rs/native_toolchain_rs.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    await const RustBuilder(
      assetName: 'uniffi:payjoin_ffi',
      cratePath: '..',
    ).run(input: input, output: output);
  });
}
