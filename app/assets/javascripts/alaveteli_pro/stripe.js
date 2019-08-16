(function() {
  'use strict';

  var subscriptionForm = document.getElementById('js-stripe-subscription-form');
  if (subscriptionForm) { stripeForm(form, {}) }
})();

function stripeForm(form, options) {
  var that = Object.assign({
    stripe: Stripe(AlaveteliPro.stripe_publishable_key),
    form: form,
    submit: document.getElementById('js-stripe-submit'),
  }, options);

  that.load = function() {
    var cardError = document.getElementById('card-errors');
    var terms = document.getElementById('js-pro-signup-terms');

    // Sync initial state for terms checkbox and submit button
    that.submit.setAttribute('disabled', 'true');
    terms.checked = false;

    // Initialise Stripe Elements
    var elements = that.stripe.elements({ locale: AlaveteliPro.stripe_locale });

    // Create an instance of the card Element.
    var style = { base: { fontSize: '16px' } };
    var card = elements.create('card', { style: style });

    // Add an instance of the card Element into the `card-element` <div>.
    card.mount('#card-element');

    // Listen to change events on the card Element and display any errors
    card.addEventListener('change', function(event) {
      if (event.error) {
        cardError.textContent = event.error.message;
      } else {
        cardError.textContent = '';
      }

      that.submitConditions.cardValid = !(event.error);
      that.updateSubmit();
    });

    terms.addEventListener('click', function(event) {
      if (this.checked) {
        that.submitConditions.termAccepted = true;
      }	else {
        that.submitConditions.termAccepted = false;
      }
      that.updateSubmit();
    });

    // Create a token or display an error when the form is submitted
    that.form.addEventListener('submit', function(event) {
      event.preventDefault();

      // Ensure submit conditions are met
      if (!that.canSubmit()) { return false; }

      that.stripe.createToken(card).then(function(result) {
        if (result.error) {
          // Inform the customer that there was an error
          cardError.textContent = result.error.message;

          // Prevent re-submitting after error
          that.submitConditions.cardValid = false;
          that.updateSubmit();

          // Reset submit button value which was changed by Rails' UJS
          // disable-with option
          var text = $(that.submit).data('ujs:enable-with');
          if (text) { $(that.submit)['val'](text); }
        } else {
          // Send the token to your server.
          that.stripeTokenHandler(result.token);
        }
      });
    });
  };

  that.canSubmit = function() {
    for (var condition in that.submitConditions) {
      if(!that.submitConditions[condition]) { return false; }
    }
    return true;
  };

  that.updateSubmit = function() {
    if (that.canSubmit()) {
      that.submit.removeAttribute('disabled');
    } else {
      that.submit.setAttribute('disabled', 'true');
    }
  };

  that.stripeTokenHandler = function(token) {
    // Insert the token ID into the form so it gets submitted to the server
    var hiddenInput = document.createElement('input');
    hiddenInput.setAttribute('type', 'hidden');
    hiddenInput.setAttribute('name', 'stripe_token');
    hiddenInput.setAttribute('value', token.id);
    that.form.appendChild(hiddenInput);

    // Submit the form
    that.form.submit();
  };

  that.load();
}
