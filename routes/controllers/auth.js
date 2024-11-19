const mysql = require("mysql");

const db = mysql.createConnection({
    host: process.env.DATABASE_HOST,
    user: process.env.DATABASE_USER,
    password: process.env.DATABASE_PASSWORD,
    database: process.env.DATABASE
})

exports.login = (req, res) => {
    const { email, password } = req.body;

    db.query('SELECT * FROM usuarios WHERE email = ?', [email], async (error, results) => {
        if (error) {
            console.log(error);
            return res.status(500).send("An error occurred during login.");
        }

        // Check if the user exists and if the password matches
        if (results.length === 0 || (password !== results[0].senha)) {
            return res.render('login', {
                message: 'Email ou senha incorretos.'
            });
        } else {
            // Here you could create a session or token if needed
            return res.render('login', {
                message: 'Login bem-sucedido!'
            });
        }
    });
}

exports.cadastro = (req,res) => {
    console.log(req.body)

    const { nome, email, password } = req.body;

    db.query('SELECT email from usuarios WHERE email = ?', [email], (error, results) => {
        if(error) {
            console.log(error);
        }

        if (results.length > 0 ) {
            console.log(results)
            return res.render('cadastro', {
                message: 'Este email já está em uso.'
            })
        } else {
            db.query('INSERT INTO usuarios SET ?', {nome: nome, email: email, senha: password}, (error, results) => {
                if(error) {
                    console.log(error);
                } else {
                    return res.render('cadastro', {
                        message: 'Cadastrado com sucesso'
                    })
                }
            })
        }
    })

   
}