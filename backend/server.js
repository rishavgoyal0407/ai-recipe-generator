import dotenv from 'dotenv';

dotenv.config();

import express from 'express'
import cors from 'cors'

import authRouter from './routes/auth.js';
import router from './routes/user.js';


const app=express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({extended:true}));

app.get('/',(req,res) => {
  res.json({message:"ai receipe generator"})
}
);

// api routes

app.use('/api/auth',authRouter);
app.use('/api/users',router);

const PORT=process.env.PORT || 8000;


app.listen(PORT,() => {
  console.log(`server running on port ${PORT}`)
}
) 