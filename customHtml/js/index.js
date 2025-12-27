function loadConfig(data) {
  IndexObj.init(data);
}

const IndexObj = {
  currentOption: "",
  loginOptions: [],

  LOGIN_OPTION: {
    VOUCHER: "voucher",
    FIXACCOUNT: "fixaccount",
    PASS: "pass",
  },

  init: function (data) {
    this.loadJson(data);
    setTimeout(function () {
      $("#body_loading").addClass("hide");
    }, 1000);

    this.initEvent();
  },

  loadJson: function (data) {
    I18nObj.init(data);
    this.renderHtml(data);
  },

  initEvent: function () {
    const self = this;
    $("#login_btn").on("click", function () {
      self.onLogin();
    });
  },

  renderHtml: function (data) {
    const loginOptions = data?.custom_html?.login_options;
    this.loginOptions = loginOptions;

    if (!loginOptions) {
      return false;
    }

    // Define priority order
    const priorityOrder = [
      this.LOGIN_OPTION.VOUCHER,
      this.LOGIN_OPTION.FIXACCOUNT,
      this.LOGIN_OPTION.PASS,
    ];
    let currentOption = null;

    // Search for the default option according to the priority order
    for (const option of priorityOrder) {
      if (loginOptions.includes(option)) {
        currentOption = option;
        this.currentOption = currentOption;
        break;
      }
    }

    if (!currentOption) {
      return false;
    }

    I18nObj.renderHtmlLang();
    this.renderLoginHtml(loginOptions);
    this.renderCurrentLogin(currentOption);
  },

  renderHtmlLang: function () {},

  renderLoginHtml: function (loginOptions) {
    // Control priority through styles: Voucher > Account > Oneclick
    if (loginOptions.length > 1) {
      $("#login_split_line").removeClass("hide");
    }

    const allOptions = [
      this.LOGIN_OPTION.VOUCHER,
      this.LOGIN_OPTION.FIXACCOUNT,
      this.LOGIN_OPTION.PASS,
    ];
    const missOptions = allOptions.filter(
      (option) => !loginOptions.includes(option)
    );

    missOptions.forEach((item) => {
      $(`.login-item-${item}`).remove();
    });
  },

  renderCurrentLogin(currentOption) {
    switch (currentOption) {
      case this.LOGIN_OPTION.PASS:
        $(".login-form-title").text(I18nObj.$t("one_click_login"));
        $('.login-form-title').attr('data-i18n', 'one_click_login')
        break;
      case this.LOGIN_OPTION.FIXACCOUNT:
        $(".login-form-title").text(I18nObj.$t("account_login"));
        $('.login-form-title').attr('data-i18n', 'account_login')
        break;
      case this.LOGIN_OPTION.VOUCHER:
      default:
        $(".login-form-title").text(I18nObj.$t("voucher_login"));
        $('.login-form-title').attr('data-i18n', 'voucher_login')
    }

    const loginOptions = this.loginOptions;
    $(".login-form-wrapper .login-item").addClass("hide");
    $(".login-form-wrapper .login-item-" + currentOption).removeClass("hide");

    $(".other-btn-wrapper .login-item").addClass("hide");
    loginOptions.forEach((loginOpt) => {
      if (loginOpt !== currentOption) {
        $(".other-btn-wrapper .login-item-" + loginOpt).removeClass("hide");
      }
    });
  },

  changeLoginOption(currentOption) {
    this.currentOption = currentOption;
    this.renderCurrentLogin(currentOption);
  },

  onLogin() {
    let paramObj = {};

    switch (this.currentOption) {
      case this.LOGIN_OPTION.FIXACCOUNT:
        paramObj.account = $("#account_input").val();
        paramObj.password = $("#account_password").val();
        break;
      case this.LOGIN_OPTION.VOUCHER:
        paramObj.account = $("#voucher_code").val();
      case this.LOGIN_OPTION.PASS:
        break;
    }

    const validRes = this.validateLoginForm();
    if (!validRes) {
      return false;
    }

    paramObj = {
      lang: I18nObj.currentLang,
      authType: this.currentOption,
      sessionId: this._getParamVal("sessionId"),
      ...paramObj,
    };

    $.post({
      url: "/api/auth/general",
      data: JSON.stringify(paramObj),
      contentType: "application/json",
      success: function (response) {
        console.log("Server Response:", response);
        if (response.success) {
          location.href = response.result.logonUrl;
        } else {
          $("#login_msg").text(response.message);
        }
      },
      error: function (jqXHR, textStatus, errorThrown) {
        console.error("Error:", textStatus, errorThrown);
      },
    });
  },

  validateLoginForm() {
    $("#login_msg").text("");
    if (!this.currentOption) {
      return true;
    }

    switch (this.currentOption) {
      case this.LOGIN_OPTION.PASS:
        break;
      case this.LOGIN_OPTION.FIXACCOUNT:
        return this.validateAccountForm();
      case this.LOGIN_OPTION.VOUCHER:
      default:
        return this.validateVoucherForm();
    }

    return true;
  },

  validateVoucherForm() {
    const voucherCode = $("#voucher_code").val().trim();
    if (!voucherCode) {
      $("#login_msg").text(I18nObj.$t("please_enter_access_code"));
      return false;
    }
    return true;
  },

  validateAccountForm() {
    const accountVal = $("#account_input").val().trim();
    const accountPwd = $("#account_password").val().trim();
    if (!accountVal) {
      $("#login_msg").text(I18nObj.$t("please_enter_account"));
      return false;
    }
    if (!accountPwd) {
      $("#login_msg").text(I18nObj.$t("please_enter_pwd"));
      return false;
    }
    return true;
  },

  _getParamVal(paras) {
    try {
      const topUrl = decodeURI(window.top.location.href);
      const queryString = topUrl.split('?')[1];
      if (!queryString) {
        return null;
      }
  
      const paraString = queryString.split('&');
      const paraObj = {};
      for (var i = 0; i < paraString.length; i++) {
        const pair = paraString[i].split('=');
        if (pair.length === 2) {
          paraObj[pair[0].toLowerCase()] = pair[1];
        }
      }
  
      const returnValue = paraObj[paras.toLowerCase()];
      return returnValue !== undefined ? returnValue : null;
    } catch (e) {
      console.error("Error accessing top window URL:", e);
      return null;
    }
  },
};
