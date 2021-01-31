const getGrainFrameDocument = () => {
    return cy
    .get('iframe.grain-frame')
    // Cypress yields jQuery element, which has the real
    // DOM element under property "0".
    // From the real DOM iframe element we can get
    // the "document" element, it is stored in "contentDocument" property
    // Cypress "its" command can access deep properties using dot notation
    // https://on.cypress.io/its
    .its('0.contentDocument').should('exist')
  }

  const getGrainFrameBody = () => {
    // get the document
    return getGrainFrameDocument()
    // automatically retries until body is loaded
    .its('body').should('not.be.undefined')
    // wraps "body" DOM element to allow
    // chaining more Cypress commands, like ".find(...)"
    .then(cy.wrap)
  }

describe('Smoke Test', () => {
    it('creates a grain, performs setup and creates a contact', () => {
        cy.visit('http://local.sandstorm.io:6080')

        // Log in and set up account
        cy.contains('with a Dev account').click()
        cy.contains('Alice (admin)').click()
        cy.contains('Continue').click()

        // Create grain
        cy.contains('Monica').click()
        cy.contains('(Dev) Create new instance').click()

        cy.frameLoaded('iframe.grain-frame', { timeout: 150 * 1000 })

        // Agree to ToS and complete initial setup
        cy.enter().then(getBody => {
            getBody().contains('Signing up signifies').children('input').check()
            getBody().contains('Register').click()
        })

        cy.wait(10000)
        cy.frameLoaded('iframe.grain-frame', { timeout: 10 * 1000 })

        // Create a contact

        cy.enter().then(getBody => {
            getBody().contains('Add your first contact').click()
        })

        cy.wait(10000)
        cy.frameLoaded('iframe.grain-frame', { timeout: 10 * 1000 })

        cy.enter().then(getBody => {
          getBody().contains('First name').parent().children('input').type('John')
          getBody().contains('Last name (Optional)').parent().children('input').type('Appleseed')
          // getBody().get('button.btn.btn-primary').contains('Add').click()
          getBody().contains('button', 'Add').click()
        })

        cy.wait(10000)
        cy.frameLoaded('iframe.grain-frame', { timeout: 10 * 1000 })

        cy.enter().then(getBody => {
          getBody().contains('John Appleseed')
        })
      })
})
