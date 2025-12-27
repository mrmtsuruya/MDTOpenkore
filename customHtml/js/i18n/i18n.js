const I18nObj = {
  labelObj: {
    en_US: "English",
    es_ES: "Español",
    fr_FR: "Français",
    th_TH: "ไทย",
    tr_TR: "Türkçe",
    vi_VN: "Tiếng Việt",
    zh_CN: "简体中文",
  },

  currentLang: "en_US",

  init: function (data) {
    const self = this;
    const langs = data?.custom_html?.lang;
    if (!langs || langs.length == 0) {
    } else {
      this.currentLang = langs[0];
      this.activedObj = LandObj[this.currentLang];
      this.renderLangMenu(langs);
      this.initEvent();
    }
  },

  renderLangMenu(langs) {
    const menuItems = [];
    langs.forEach((lang) => {
      menuItems.push(`
          <a href="javascript:void(0)" onclick="I18nObj.changeLang('${lang}')">
            ${I18nObj.labelObj[lang]}
          </a>
        `);
    });
    $("#body_content").append(`
         <div class="dropdown language-select" id="language_select">
          <span class="dropdown-label">English</span>
          <span class="dropdown-arrow">▼</span>

          <span class="dropdown-menu">
            ${menuItems.join("")}
          </span>
        </div>  
      `);
  },

  initEvent() {
    const self = this;
    $("#body_content").on("click", "#language_select", function (event) {
      $(this).toggleClass("actived");
    });
  },

  $t: function (key) {
    if (this.activedObj[key]) {
      return this.activedObj[key];
    } else {
      return key;
    }
  },

  changeLang(lang) {
    $("#login_msg").text(""); // Clear error message
    $(".dropdown-label").text(I18nObj.labelObj[lang]);

    this.currentLang = lang;
    this.activedObj = LandObj[lang]
    this.renderHtmlLang();
  },

  renderHtmlLang() {
    // For text content
    $("[data-i18n]").each(function () {
      var key = $(this).data("i18n");
      var translation = I18nObj.$t(key);
      $(this).text(translation);
    });

    $("[data-i18n-placeholder]").each(function () {
      var key = $(this).data("i18n-placeholder");
      var translation = I18nObj.$t(key);
      $(this).prop("placeholder", translation);
    });
  },
};
