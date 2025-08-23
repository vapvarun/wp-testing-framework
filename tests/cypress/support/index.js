// WordPress login command
Cypress.Commands.add('login', (username, password) => {
    cy.visit('/wp-login.php');
    cy.get('#user_login').type(username || Cypress.env('WP_USER'));
    cy.get('#user_pass').type(password || Cypress.env('WP_PASS'));
    cy.get('#wp-submit').click();
    cy.url().should('include', '/wp-admin');
});

// Visit admin page
Cypress.Commands.add('visitAdmin', (path) => {
    cy.visit(`/wp-admin/${path}`);
});
