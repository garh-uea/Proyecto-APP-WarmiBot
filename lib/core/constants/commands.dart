// ============================================================
// WarmiBot — Mapa de comandos (equivalente a CMDS en Python)
// ============================================================

enum CommandType {
  hora,
  fecha,
  saludo,
  musica,
  buscar,
  clima,
  chiste,
  temporizador,
  alarma,
  recordatorio,
  abrir,
  whatsapp,
  suscriptores,
  edad,
  traducir,
  noticias,
  calculadora,
  salir,
  desconocido,
}

class Commands {
  Commands._();

  static const Map<CommandType, List<String>> variants = {
    CommandType.hora: ['hora', 'que hora es', 'dime la hora', 'hora actual'],
    CommandType.fecha: ['fecha', 'que fecha es', 'que dia es', 'dia actual'],
    CommandType.saludo: ['hola', 'estas ahi', 'me escuchas', 'buenos dias', 'buenas tardes', 'buenas noches'],
    CommandType.musica: ['reproduce', 'pon musica', 'toca', 'quiero escuchar'],
    CommandType.buscar: ['busca', 'buscar', 'que es', 'dime sobre', 'informacion sobre', 'quien es'],
    CommandType.clima: ['clima', 'temperatura', 'tiempo en', 'como esta el tiempo', 'va a llover'],
    CommandType.chiste: ['chiste', 'broma', 'hazme reir', 'cuentame algo gracioso'],
    CommandType.temporizador: ['temporizador', 'timer', 'cuenta regresiva', 'cronometro'],
    CommandType.alarma: ['alarma', 'despiertame', 'activa alarma', 'pon una alarma'],
    CommandType.recordatorio: ['recordatorio', 'recuerdame', 'avisame', 'no olvidar'],
    CommandType.abrir: ['abre', 'abrir', 'ir a', 'mostrar'],
    CommandType.whatsapp: ['envia mensaje', 'manda mensaje', 'mensaje a', 'whatsapp a'],
    CommandType.suscriptores: ['cuantos suscriptores', 'suscriptores de', 'suscriptores tiene'],
    CommandType.edad: ['mi edad', 'calcula mi edad', 'cuantos anos tengo', 'cuantos años tengo'],
    CommandType.traducir: ['traduce', 'traducir', 'como se dice', 'en ingles', 'en frances'],
    CommandType.noticias: ['noticias', 'novedades', 'que paso', 'informacion de hoy'],
    CommandType.calculadora: ['cuanto es', 'calcula', 'cuanto da', 'resultado de'],
    CommandType.salir: ['salir', 'adios', 'chao', 'hasta luego', 'apagate', 'descansa', 'hasta pronto'],
  };

  /// Acciones rápidas visibles en el grid de la pantalla principal
  static const List<QuickAction> quickActions = [
    QuickAction(label: 'Traducir',      icon: '🌍', command: 'traduce buenos dias al ingles'),
    QuickAction(label: 'Clima',         icon: '☁️', command: 'clima en Tena'),
    QuickAction(label: 'Noticias',      icon: '📰', command: 'noticias'),
    QuickAction(label: 'Alarmas',       icon: '⏰', command: 'alarma a las 7 con 0'),
    QuickAction(label: 'Recordatorios', icon: '📌', command: 'recuerdame'),
    QuickAction(label: 'Buscar info',   icon: '🔍', command: 'busca'),
    QuickAction(label: 'Música',        icon: '🎵', command: 'reproduce'),
    QuickAction(label: 'Chistes',       icon: '😂', command: 'chiste'),
  ];
}

class QuickAction {
  final String label;
  final String icon;
  final String command;

  const QuickAction({
    required this.label,
    required this.icon,
    required this.command,
  });
}
