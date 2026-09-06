/// Uniform result shape every state controller mutation returns — screens
/// show `message` in a snackbar/inline banner either way, per README §10
/// "no silent failures".
class OpResult {
  final bool success;
  final String message;
  final String? id;
  const OpResult(this.success, this.message, {this.id});
}
