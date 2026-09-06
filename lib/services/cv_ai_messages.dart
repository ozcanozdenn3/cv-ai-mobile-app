// Regional variants share their base-language messages.
class CvAiMessages {
  static String? lookup(String locale, String key) {
    if (key == 'cv_ai_configuration_error') key = 'cv_ai_not_configured';
    final messages = _messages[key];
    return messages?[locale.split(RegExp('[_-]')).first] ?? messages?['en'];
  }

  static const _messages = <String, Map<String, String>>{
    'cv_ai_not_configured': {
      'en':
          'The AI connection is missing or invalid. Check the service configuration.',
      'tr':
          'AI bağlantısı tanımlı değil veya geçersiz. Servis yapılandırmasını kontrol edin.',
      'de':
          'Die KI-Verbindung fehlt oder ist ungültig. Prüfen Sie die Dienstkonfiguration.',
      'fr':
          'La connexion IA est absente ou invalide. Vérifiez la configuration du service.',
      'es':
          'La conexión de IA no está configurada o no es válida. Revisa la configuración del servicio.',
      'pt':
          'A ligação à IA não está configurada ou é inválida. Verifique a configuração do serviço.',
      'it':
          'La connessione IA è assente o non valida. Controlla la configurazione del servizio.',
      'nl':
          'De AI-verbinding ontbreekt of is ongeldig. Controleer de serviceconfiguratie.',
      'pl':
          'Brak połączenia z AI lub jest ono nieprawidłowe. Sprawdź konfigurację usługi.',
      'ru':
          'Подключение к ИИ не настроено или недействительно. Проверьте настройки сервиса.',
      'ar':
          'اتصال الذكاء الاصطناعي غير مُعدّ أو غير صالح. تحقق من إعدادات الخدمة.',
      'hi': 'AI कनेक्शन उपलब्ध नहीं है या अमान्य है। सेवा की सेटिंग जाँचें।',
      'zh': 'AI 连接未配置或无效。请检查服务配置。',
      'ja': 'AI接続が未設定または無効です。サービス設定を確認してください。',
      'ko': 'AI 연결이 설정되지 않았거나 유효하지 않습니다. 서비스 설정을 확인하세요.',
      'id':
          'Koneksi AI belum diatur atau tidak valid. Periksa konfigurasi layanan.',
    },
    'cv_ai_request_failed': {
      'en':
          'The content could not be processed completely. Check your connection and try again.',
      'tr':
          'İçerik tamamen işlenemedi. Bağlantınızı kontrol edip tekrar deneyin.',
      'de':
          'Der Inhalt konnte nicht vollständig verarbeitet werden. Prüfen Sie die Verbindung und versuchen Sie es erneut.',
      'fr':
          'Le contenu n’a pas pu être traité entièrement. Vérifiez votre connexion et réessayez.',
      'es':
          'No se pudo procesar todo el contenido. Comprueba tu conexión e inténtalo de nuevo.',
      'pt':
          'Não foi possível processar todo o conteúdo. Verifique a ligação e tente novamente.',
      'it':
          'Impossibile elaborare tutto il contenuto. Controlla la connessione e riprova.',
      'nl':
          'De inhoud kon niet volledig worden verwerkt. Controleer je verbinding en probeer opnieuw.',
      'pl':
          'Nie udało się przetworzyć całej treści. Sprawdź połączenie i spróbuj ponownie.',
      'ru':
          'Не удалось обработать содержимое полностью. Проверьте подключение и повторите попытку.',
      'ar': 'تعذرت معالجة المحتوى بالكامل. تحقق من اتصالك وحاول مجددًا.',
      'hi':
          'पूरी सामग्री संसाधित नहीं हो सकी। अपना कनेक्शन जाँचें और फिर प्रयास करें।',
      'zh': '未能完整处理内容。请检查网络连接后重试。',
      'ja': '内容を最後まで処理できませんでした。接続を確認して再試行してください。',
      'ko': '내용을 완전히 처리하지 못했습니다. 연결을 확인하고 다시 시도하세요.',
      'id':
          'Konten tidak dapat diproses sepenuhnya. Periksa koneksi dan coba lagi.',
    },
    'cv_ai_busy': {
      'en': 'The AI usage limit has been reached. Please try again later.',
      'tr': 'AI kullanım sınırına ulaşıldı. Lütfen daha sonra tekrar deneyin.',
      'de':
          'Das KI-Nutzungslimit wurde erreicht. Bitte versuchen Sie es später erneut.',
      'fr':
          'La limite d’utilisation de l’IA est atteinte. Réessayez plus tard.',
      'es': 'Se alcanzó el límite de uso de IA. Inténtalo más tarde.',
      'pt':
          'O limite de utilização da IA foi atingido. Tente novamente mais tarde.',
      'it': 'Limite di utilizzo IA raggiunto. Riprova più tardi.',
      'nl': 'De AI-gebruikslimiet is bereikt. Probeer het later opnieuw.',
      'pl': 'Osiągnięto limit korzystania z AI. Spróbuj ponownie później.',
      'ru': 'Достигнут лимит использования ИИ. Попробуйте позже.',
      'ar': 'تم بلوغ حد استخدام الذكاء الاصطناعي. حاول لاحقًا.',
      'hi': 'AI उपयोग सीमा पूरी हो गई है। कृपया बाद में प्रयास करें।',
      'zh': '已达到 AI 使用限额。请稍后重试。',
      'ja': 'AIの利用上限に達しました。後でもう一度お試しください。',
      'ko': 'AI 사용 한도에 도달했습니다. 나중에 다시 시도하세요.',
      'id': 'Batas penggunaan AI tercapai. Silakan coba lagi nanti.',
    },
    'cv_ai_file_invalid': {
      'en':
          'This file is empty, too large or unsupported. Select another PDF or image.',
      'tr':
          'Dosya boş, çok büyük veya desteklenmiyor. Başka bir PDF ya da görsel seçin.',
      'de':
          'Die Datei ist leer, zu groß oder nicht unterstützt. Wählen Sie eine andere PDF- oder Bilddatei.',
      'fr':
          'Ce fichier est vide, trop volumineux ou non pris en charge. Choisissez un autre PDF ou une image.',
      'es':
          'El archivo está vacío, es demasiado grande o no es compatible. Selecciona otro PDF o imagen.',
      'pt':
          'O ficheiro está vazio, é demasiado grande ou não é suportado. Selecione outro PDF ou imagem.',
      'it':
          'Il file è vuoto, troppo grande o non supportato. Seleziona un altro PDF o un’immagine.',
      'nl':
          'Dit bestand is leeg, te groot of niet ondersteund. Kies een andere PDF of afbeelding.',
      'pl':
          'Plik jest pusty, zbyt duży lub nieobsługiwany. Wybierz inny PDF lub obraz.',
      'ru':
          'Файл пуст, слишком велик или не поддерживается. Выберите другой PDF или изображение.',
      'ar': 'الملف فارغ أو كبير جدًا أو غير مدعوم. اختر ملف PDF أو صورة أخرى.',
      'hi':
          'फ़ाइल खाली है, बहुत बड़ी है या समर्थित नहीं है। दूसरी PDF या छवि चुनें।',
      'zh': '文件为空、过大或不受支持。请选择其他 PDF 或图片。',
      'ja': '空のファイル、サイズ超過、または非対応の形式です。別のPDFか画像を選択してください。',
      'ko': '파일이 비어 있거나 너무 크거나 지원되지 않습니다. 다른 PDF 또는 이미지를 선택하세요.',
      'id':
          'File kosong, terlalu besar, atau tidak didukung. Pilih PDF atau gambar lain.',
    },
    'cv_ai_summary_updated': {
      'en': 'Professional summary updated.',
      'tr': 'Profesyonel özet geliştirildi.',
      'de': 'Berufliche Zusammenfassung aktualisiert.',
      'fr': 'Résumé professionnel amélioré.',
      'es': 'Resumen profesional mejorado.',
      'pt': 'Resumo profissional melhorado.',
      'it': 'Riepilogo professionale migliorato.',
      'nl': 'Professionele samenvatting bijgewerkt.',
      'pl': 'Podsumowanie zawodowe zostało ulepszone.',
      'ru': 'Профессиональное резюме улучшено.',
      'ar': 'تم تحسين الملخص المهني.',
      'hi': 'पेशेवर सारांश बेहतर किया गया।',
      'zh': '职业简介已优化。',
      'ja': '職務要約を改善しました。',
      'ko': '전문 요약이 개선되었습니다.',
      'id': 'Ringkasan profesional diperbarui.',
    },
    'cv_ai_local_extraction': {
      'en': 'Text imported. AI is not connected; check the extracted fields.',
      'tr': 'Metin aktarıldı. AI bağlı değil; çıkarılan alanları kontrol edin.',
      'de':
          'Text importiert. KI ist nicht verbunden; prüfen Sie die erkannten Felder.',
      'fr':
          'Texte importé. L’IA n’est pas connectée ; vérifiez les champs extraits.',
      'es':
          'Texto importado. La IA no está conectada; revisa los campos extraídos.',
      'pt':
          'Texto importado. A IA não está ligada; verifique os campos extraídos.',
      'it': 'Testo importato. IA non connessa; verifica i campi estratti.',
      'nl':
          'Tekst geïmporteerd. AI is niet verbonden; controleer de ingevulde velden.',
      'pl':
          'Tekst zaimportowany. AI nie jest połączona; sprawdź wyodrębnione pola.',
      'ru': 'Текст импортирован. ИИ не подключён; проверьте заполненные поля.',
      'ar':
          'تم استيراد النص. الذكاء الاصطناعي غير متصل؛ تحقق من الحقول المستخرجة.',
      'hi': 'टेक्स्ट आयात हुआ। AI जुड़ा नहीं है; निकाले गए फ़ील्ड जाँचें।',
      'zh': '文本已导入。AI 未连接，请检查提取的字段。',
      'ja': 'テキストを取り込みました。AI未接続のため、抽出された項目を確認してください。',
      'ko': '텍스트를 가져왔습니다. AI가 연결되지 않았으니 추출된 항목을 확인하세요.',
      'id': 'Teks diimpor. AI belum terhubung; periksa bidang yang diekstrak.',
    },
  };
}
