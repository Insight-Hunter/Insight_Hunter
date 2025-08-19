const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

const app = express();
app.use(cors());
app.use(bodyParser.json());

const JWT_SECRET = process.env.JWT_SECRET || "supersecretjwtkey";

function authenticateToken(req,res,next){
  const token = req.headers["authorization"]?.split(" ")[1];
  if (!token) return res.sendStatus(401);
  jwt.verify(token, JWT_SECRET, (err,user)=>{
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
}

app.get("/", (req,res)=>res.json({status:"Backend running"}));

app.post("/auth/register", async (req,res)=>{
  const { email, password } = req.body;
  const hashed = await bcrypt.hash(password,10);
  try {
    const user = await prisma.user.create({ data: { email, password: hashed } });
    res.json(user);
  } catch {
    res.status(400).json({error:"User exists"});
  }
});

app.post("/auth/login", async (req,res)=>{
  const { email, password } = req.body;
  const user = await prisma.user.findUnique({where:{email}});
  if (!user) return res.status(400).json({error:"Invalid credentials"});
  const match = await bcrypt.compare(password,user.password);
  if (!match) return res.status(400).json({error:"Invalid credentials"});
  const token = jwt.sign({id:user.id,email:user.email},JWT_SECRET,{expiresIn:"1d"});
  res.json({token,user});
});

app.post("/auth/forgot", async (req,res)=>{
  const { email } = req.body;
  const token = Math.random().toString(36).substring(2);
  try {
    await prisma.user.update({ where:{email}, data:{resetToken:token} });
    res.json({message:"Reset token generated", token});
  } catch {
    res.status(400).json({error:"No such user"});
  }
});

app.post("/auth/reset", async (req,res)=>{
  const { token, password } = req.body;
  const hashed = await bcrypt.hash(password,10);
  const user = await prisma.user.updateMany({
    where:{resetToken:token},
    data:{password:hashed, resetToken:null}
  });
  if (!user.count) return res.status(400).json({error:"Invalid token"});
  res.json({message:"Password reset"});
});

app.patch("/users/:id/demo-mode", authenticateToken, async (req,res)=>{
  const { demoMode } = req.body;
  const { id } = req.params;
  if (req.user.id !== id) return res.sendStatus(403);
  const user = await prisma.user.update({ where: { id }, data: { demoMode } });
  res.json(user);
});

app.get("/reports", authenticateToken, async (req,res)=>{
  res.json({
    insights:[
      "Revenue grew 12% this month",
      "Expenses trending lower than last quarter",
      "Healthy cash flow maintained"
    ]
  });
});

const PORT=4000;
app.listen(PORT,()=>console.log("Backend running on "+PORT));
