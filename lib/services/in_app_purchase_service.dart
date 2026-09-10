import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/subscription_model.dart';
import 'auth_service.dart';

/// Apple StoreKit & Google Play Billing Resmi Abonelik Servisi
class InAppPurchaseService {
  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  // App Store Connect & Google Play Console Ürün Kimlikleri
  static const String weeklyProductId = 'com.ozdentech.cvai.weekly';
  static const String monthlyProductId = 'com.ozdentech.cvai.monthly';
  static const String yearlyProductId = 'com.ozdentech.cvai.yearly';

  static const Set<String> productIds = {
    weeklyProductId,
    monthlyProductId,
    yearlyProductId,
  };

  /// Mağazadan çekilen canlı ürün detayları (fiyat, para birimi vb.)
  static final ValueNotifier<Map<String, ProductDetails>> productsNotifier =
      ValueNotifier<Map<String, ProductDetails>>({});

  /// Mağaza (StoreKit / Google Play) erişilebilir mi?
  static final ValueNotifier<bool> isStoreAvailableNotifier =
      ValueNotifier<bool>(false);

  /// Satın alma veya geri yükleme işlemi sürüyor mu?
  static final ValueNotifier<bool> isProcessingNotifier =
      ValueNotifier<bool>(false);

  /// Son gerçekleşen durum mesajı (UI geri bildirimi için)
  static final ValueNotifier<String?> purchaseStatusMessageNotifier =
      ValueNotifier<String?>(null);

  /// Servisi başlatır, stream'i dinler ve ürün detaylarını yükler
  static Future<void> init() async {
    try {
      final isAvailable = await _iap.isAvailable();
      isStoreAvailableNotifier.value = isAvailable;

      if (!isAvailable) {
        debugPrint('⚠️ InAppPurchase: Mağaza servisi şu an erişilebilir değil.');
        return;
      }

      // Varsa eski abonelik dinleyicisini kapatıp yenisini aç
      await _purchaseSubscription?.cancel();
      _purchaseSubscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _purchaseSubscription?.cancel(),
        onError: (error) {
          debugPrint('❌ InAppPurchase stream hatası: $error');
          isProcessingNotifier.value = false;
        },
      );

      // Mağazadan ürünleri çek
      await loadProducts();
    } catch (e) {
      debugPrint('❌ InAppPurchaseService başlatma hatası: $e');
      isStoreAvailableNotifier.value = false;
    }
  }

  /// App Store ve Google Play'den canlı fiyat ve ürün bilgilerini çeker
  static Future<void> loadProducts() async {
    try {
      final response = await _iap.queryProductDetails(productIds);
      if (response.error != null) {
        debugPrint('❌ Ürünleri çekerken hata: ${response.error!.message}');
        return;
      }

      final Map<String, ProductDetails> map = {};
      for (final product in response.productDetails) {
        map[product.id] = product;
      }
      productsNotifier.value = map;
      debugPrint('✅ InAppPurchase: ${map.length} adet ürün başarıyla yüklendi.');
    } catch (e) {
      debugPrint('❌ InAppPurchase loadProducts hatası: $e');
    }
  }

  /// İlgili Tier için StoreKit/Google Play satın alma akışını başlatır
  static Future<bool> buySubscription(SubscriptionTier tier) async {
    final productId = productIdForTier(tier);
    debugPrint('🛒 Satın alma başlatılıyor: $tier -> $productId');
    
    final product = productsNotifier.value[productId];

    if (product == null) {
      debugPrint('⚠️ Satın alınacak ürün mağazada bulunamadı: $productId');
      debugPrint('📦 Mevcut ürünler: ${productsNotifier.value.keys.join(", ")}');
      // Ürün henüz yüklenmemişse tekrar yüklemeyi dene
      await loadProducts();
      final retryProduct = productsNotifier.value[productId];
      if (retryProduct == null) {
        debugPrint('❌ Ürün yeniden yüklenemiyor: $productId');
        purchaseStatusMessageNotifier.value = 'product_not_found';
        return false;
      }
    }

    try {
      isProcessingNotifier.value = true;
      final targetProduct = productsNotifier.value[productId]!;
      debugPrint('✅ Ürün bulundu: ${targetProduct.title} - ${targetProduct.price}');
      final purchaseParam = PurchaseParam(productDetails: targetProduct);

      // Otomatik yenilenen abonelikler StoreKit/Google Play'de buyNonConsumable ile tetiklenir
      final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      debugPrint('🔄 Satın alma durumu: $started');
      if (!started) {
        isProcessingNotifier.value = false;
      }
      return started;
    } catch (e) {
      debugPrint('❌ Satın alma başlatma hatası: $e');
      isProcessingNotifier.value = false;
      purchaseStatusMessageNotifier.value = 'purchase_failed: $e';
      return false;
    }
  }

  /// Satın alımları geri yükler (Apple App Store Guideline 3.1.1 zorunluluğu)
  static Future<void> restorePurchases() async {
    try {
      isProcessingNotifier.value = true;
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('❌ Geri yükleme hatası: $e');
      isProcessingNotifier.value = false;
      purchaseStatusMessageNotifier.value = 'restore_failed: $e';
    }
  }

  /// Apple ve Google mağazasından gelen satın alma akış güncellemelerini işler
  static Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      debugPrint(
          'ℹ️ InAppPurchase güncellemesi: ${purchaseDetails.productID} -> ${purchaseDetails.status}');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          isProcessingNotifier.value = true;
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _deliverProduct(purchaseDetails);
          if (purchaseDetails.pendingCompletePurchase) {
            await _iap.completePurchase(purchaseDetails);
          }
          isProcessingNotifier.value = false;
          purchaseStatusMessageNotifier.value =
              purchaseDetails.status == PurchaseStatus.purchased
                  ? 'purchase_success'
                  : 'restore_success';
          break;

        case PurchaseStatus.error:
          isProcessingNotifier.value = false;
          debugPrint('❌ Satın alma hatası: ${purchaseDetails.error?.message}');
          if (purchaseDetails.pendingCompletePurchase) {
            await _iap.completePurchase(purchaseDetails);
          }
          purchaseStatusMessageNotifier.value =
              'error: ${purchaseDetails.error?.message}';
          break;

        case PurchaseStatus.canceled:
          isProcessingNotifier.value = false;
          debugPrint('ℹ️ Satın alma kullanıcı tarafından iptal edildi.');
          purchaseStatusMessageNotifier.value = 'canceled';
          break;
      }
    }
  }

  /// Satın alma başarıyla doğrulandığında kullanıcıya PRO yetkilerini verir
  static Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    final tier = tierForProductId(purchaseDetails.productID);
    if (tier != null) {
      debugPrint('🎉 Kullanıcı başarıyla yükseltiliyor: $tier');
      await AuthService.upgradeToPro(tier: tier);
    }
  }

  /// Tier'dan Product ID'ye dönüşüm
  static String productIdForTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.weekly:
        return weeklyProductId;
      case SubscriptionTier.monthly:
        return monthlyProductId;
      case SubscriptionTier.yearly:
      case SubscriptionTier.unlimited:
        return yearlyProductId;
    }
  }

  /// Product ID'den Tier'a dönüşüm
  static SubscriptionTier? tierForProductId(String id) {
    switch (id) {
      case weeklyProductId:
        return SubscriptionTier.weekly;
      case monthlyProductId:
        return SubscriptionTier.monthly;
      case yearlyProductId:
        return SubscriptionTier.yearly;
      default:
        return null;
    }
  }

  /// Canlı mağaza fiyatını getirir (Bulunamazsa null döner)
  static String? getFormattedPrice(SubscriptionTier tier) {
    final id = productIdForTier(tier);
    return productsNotifier.value[id]?.price;
  }

  /// Servis kapatılırken dinleyiciyi temizler
  static void dispose() {
    _purchaseSubscription?.cancel();
  }
}
