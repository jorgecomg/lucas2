const express = require('express');

const router = express.Router();

router.get('/login', (req, res) => {
    res.render('login');
})

router.get('/', (req, res) => {
    res.render('login');
})

router.get('/cadastro', (req, res) => {
    res.render('cadastro');
})

module.exports = router;