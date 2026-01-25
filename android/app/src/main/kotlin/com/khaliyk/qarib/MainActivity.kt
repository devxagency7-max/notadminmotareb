package com.khaliyk.qarib

import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Small Layout Factory (For Home Content)
        GoogleMobileAdsPlugin.registerNativeAdFactory(
                flutterEngine,
                "listTileSmall",
                ListTileSmallFactory(layoutInflater)
        )

        // Medium Layout Factory (For Search/University Content)
        GoogleMobileAdsPlugin.registerNativeAdFactory(
                flutterEngine,
                "listTileMedium",
                ListTileMediumFactory(layoutInflater)
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "listTileSmall")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "listTileMedium")
    }
}

// Factory for Medium Layout (With MediaView)
class ListTileMediumFactory(private val layoutInflater: LayoutInflater) :
        GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(
            nativeAd: NativeAd,
            customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = layoutInflater.inflate(R.layout.native_ad_medium, null) as NativeAdView

        adView.mediaView = adView.findViewById(R.id.ad_media)
        adView.headlineView = adView.findViewById(R.id.ad_headline)
        adView.bodyView = adView.findViewById(R.id.ad_body)
        adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)
        adView.iconView = adView.findViewById(R.id.ad_app_icon)
        adView.advertiserView = adView.findViewById(R.id.ad_advertiser)

        (adView.headlineView as TextView).text = nativeAd.headline
        if (nativeAd.mediaContent != null) {
            adView.mediaView?.setMediaContent(nativeAd.mediaContent!!)
        }

        if (nativeAd.body == null) {
            adView.bodyView?.visibility = View.INVISIBLE
        } else {
            adView.bodyView?.visibility = View.VISIBLE
            (adView.bodyView as TextView).text = nativeAd.body
        }

        if (nativeAd.callToAction == null) {
            adView.callToActionView?.visibility = View.INVISIBLE
        } else {
            adView.callToActionView?.visibility = View.VISIBLE
            (adView.callToActionView as Button).text = nativeAd.callToAction
        }

        if (nativeAd.icon == null) {
            adView.iconView?.visibility = View.GONE
        } else {
            (adView.iconView as ImageView).setImageDrawable(nativeAd.icon?.drawable)
            adView.iconView?.visibility = View.VISIBLE
        }

        if (nativeAd.advertiser == null) {
            adView.advertiserView?.visibility = View.INVISIBLE
        } else {
            (adView.advertiserView as TextView).text = nativeAd.advertiser
            adView.advertiserView?.visibility = View.VISIBLE
        }

        adView.setNativeAd(nativeAd)
        return adView
    }
}

// Factory for Small Layout (Without MediaView)
class ListTileSmallFactory(private val layoutInflater: LayoutInflater) :
        GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(
            nativeAd: NativeAd,
            customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = layoutInflater.inflate(R.layout.native_ad_small, null) as NativeAdView

        adView.headlineView = adView.findViewById(R.id.ad_headline)
        adView.bodyView = adView.findViewById(R.id.ad_body)
        adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)
        adView.iconView = adView.findViewById(R.id.ad_app_icon)

        (adView.headlineView as TextView).text = nativeAd.headline

        if (nativeAd.body == null) {
            adView.bodyView?.visibility = View.INVISIBLE
        } else {
            adView.bodyView?.visibility = View.VISIBLE
            (adView.bodyView as TextView).text = nativeAd.body
        }

        if (nativeAd.callToAction == null) {
            adView.callToActionView?.visibility = View.INVISIBLE
        } else {
            adView.callToActionView?.visibility = View.VISIBLE
            (adView.callToActionView as Button).text = nativeAd.callToAction
        }

        if (nativeAd.icon == null) {
            adView.iconView?.visibility = View.GONE
        } else {
            (adView.iconView as ImageView).setImageDrawable(nativeAd.icon?.drawable)
            adView.iconView?.visibility = View.VISIBLE
        }

        adView.setNativeAd(nativeAd)
        return adView
    }
}
