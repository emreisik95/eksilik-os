# Harici Bağlantı Sunumu ve Uygulama Yönlendirmesi

Entry içindeki harici bağlantı göstergesi emoji değil, metin sunumuna zorlanan `↗︎` karakteri olacak. Bunun için kuzeydoğu okundan sonra Unicode text variation selector (`U+FE0E`) eklenir; emoji variation selector hiçbir aşamada üretilmez.

X, Instagram, Threads, YouTube, TikTok, LinkedIn ve benzeri yaygın sosyal/medya alan adları saf Foundation tabanlı bir politika tarafından tanınır. Kullanıcı bu bağlantılara dokunduğunda iOS universal link açılışı önce yalnız kurulu uygulama için denenir. İlgili uygulama yoksa mevcut `SFSafariViewController` davranışına geri dönülür. Diğer web siteleri doğrudan uygulama içi tarayıcıda kalır. Alan adı karşılaştırması tam alan adı veya gerçek alt alan adı üzerinden yapılır; `notx.com` gibi benzer görünen alan adları kabul edilmez.

Politika UIKit'ten ayrıdır ve hem taşınabilir çekirdek testlerinde hem XCTest'te; Unicode sunumu, desteklenen sosyal alan adları, sıradan alan adları ve sahte benzer alan adlarıyla doğrulanır.
