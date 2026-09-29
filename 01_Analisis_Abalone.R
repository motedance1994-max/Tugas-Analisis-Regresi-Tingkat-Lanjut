# Paket Abalone: turunan skrip unggahan, dengan perubahan terdokumentasi.
# Protokol utama dipertahankan: inferensi seluruh data, LCG 2026, 80:20,
# fold 1:5 pada urutan latih, ntree=300/mtry=3, seed RF=2026+k dan 3030.
# Lihat CHANGELOG.md. Skrip ini belum dieksekusi pada lingkungan penyusun.
# Di RStudio: buka Abalone_Project.Rproj, source skrip, lalu analisis_abalone().

analisis_abalone <- function(file_csv = "data/abalone.csv",
                            output_dir = "hasil_R", bootstrap_B = 2000L) {
  wajib <- c("rpart", "randomForest")
  hilang <- wajib[!vapply(wajib, requireNamespace, logical(1), quietly = TRUE)]
  if (length(hilang)) stop("Pasang paket lebih dahulu: install.packages(c(",
    paste(sprintf('"%s"', hilang), collapse = ", "), "))")
  if (!file.exists(file_csv)) stop("CSV tidak ditemukan: ", file_csv,
    ". Buka Abalone_Project.Rproj atau gunakan jalur CSV lengkap.")
  if (bootstrap_B < 100L) stop("bootstrap_B minimal 100.")
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
d <- read.csv(file_csv, stringsAsFactors = FALSE)
kolom <- c("Sex", "Length", "Diameter", "Height", "Whole_weight",
           "Shucked_weight", "Viscera_weight", "Shell_weight", "Rings")
if (!identical(names(d), kolom)) {
  stop("Nama/urutan kolom CSV tidak sesuai: ", paste(names(d), collapse = ", "))
}
d$Sex <- factor(d$Sex, levels = c("F", "I", "M"))
if (anyNA(d) || !all(vapply(d[-1], is.numeric, logical(1)))) {
  stop("Ada nilai kosong, kategori Sex lain, atau kolom numerik belum terbaca.")
}
if (any(!is.finite(as.matrix(d[-1])))) stop("Ada nilai numerik tidak hingga.")

cat("\nLANGKAH 1: DATA\n")
cat("Jumlah baris:", nrow(d), "\n")
print(table(d$Sex))
print(summary(d$Rings))
cat("Nilai kosong:", sum(is.na(d)), "\n")
cat("Baris duplikat:", sum(duplicated(d)), "\n")
cat("Baris Height <= 0 atau > 0.3 (perlu diperiksa):\n")
print(data.frame(baris_asli = which(d$Height <= 0 | d$Height > 0.3),
                 d[d$Height <= 0 | d$Height > 0.3,
                   c("Length", "Height", "Rings"), drop = FALSE]))

# 2. Hitung manual regresi sederhana, lalu verifikasi dengan lm() -----------
# H0: koefisien Shell_weight = 0; H1: koefisien Shell_weight != 0.
# Koefisien menunjukkan asosiasi rerata, tidak membuktikan sebab akibat.
x <- d$Shell_weight
y <- d$Rings
n <- length(y)
Sxx <- sum(x^2) - sum(x)^2 / n
Sxy <- sum(x * y) - sum(x) * sum(y) / n
b1_manual <- Sxy / Sxx
b0_manual <- mean(y) - b1_manual * mean(x)
y_topi <- b0_manual + b1_manual * x
SSE <- sum((y - y_topi)^2)
SST <- sum((y - mean(y))^2)
R2_manual <- 1 - SSE / SST

cat("\nLANGKAH 2: REGRESI SEDERHANA SECARA MANUAL\n")
print(c(n = n, jumlah_x = sum(x), jumlah_y = sum(y),
        jumlah_x2 = sum(x^2), jumlah_xy = sum(x * y),
        Sxx = Sxx, Sxy = Sxy, intersep = b0_manual,
        kemiringan = b1_manual, SSE = SSE, SST = SST,
        R2 = R2_manual))
mod_infer <- lm(Rings ~ Shell_weight, data = d)
print(summary(mod_infer))
cat("Interval kepercayaan OLS 95%:\n")
print(confint(mod_infer))
stopifnot(isTRUE(all.equal(unname(coef(mod_infer)),
                           unname(c(b0_manual, b1_manual)), tolerance = 1e-9)))

# SE HC3 lebih tahan terhadap perubahan ragam residual; hanya base R.
hc3 <- function(model) {
  X <- model.matrix(model)
  e <- residuals(model)
  h <- hatvalues(model)
  bread <- solve(crossprod(X))
  V <- bread %*% crossprod(X, X * (e / (1 - h))^2) %*% bread
  se <- sqrt(diag(V))
  beta <- coef(model)
  df <- df.residual(model)
  data.frame(variabel = names(beta), koefisien = unname(beta),
             SE_HC3 = unname(se),
             p_HC3 = unname(2 * pt(-abs(beta / se), df)),
             CI95_bawah_HC3 = unname(beta - qt(0.975, df) * se),
             CI95_atas_HC3 = unname(beta + qt(0.975, df) * se),
             row.names = NULL)
}
cat("Interval dan p dengan SE HC3 (pendekatan sampel besar):\n")
print(hc3(mod_infer))

# Model berganda bersifat eksploratif: banyak ukuran tubuh saling berkorelasi.
rumus_penuh <- Rings ~ Sex + Length + Diameter + Height + Whole_weight +
  Shucked_weight + Viscera_weight + Shell_weight
mod_penuh <- lm(rumus_penuh, data = d)
cat("\nLANGKAH 3: MODEL BERGANDA DAN DIAGNOSTIK\n")
print(summary(mod_penuh))
cat("Koefisien dan ketidakpastian HC3 model berganda:\n")
print(hc3(mod_penuh))
cat("Lima baris dengan Cook's distance terbesar:\n")
urutan_cook <- order(cooks.distance(mod_penuh), decreasing = TRUE)[1:5]
print(data.frame(baris_asli = urutan_cook,
                 cooks_distance = cooks.distance(mod_penuh)[urutan_cook]))

# Analisis sensitivitas, bukan penghapusan otomatis pada analisis utama.
mod_sensitivitas <- lm(rumus_penuh,
                      data = d[d$Height > 0 & d$Height <= 0.3, ])
cat("Koefisien Height: seluruh data dan tanpa Height ekstrem:\n")
print(c(semua_data = coef(mod_penuh)["Height"],
        tanpa_height_ekstrem = coef(mod_sensitivitas)["Height"]))

# 4. Bagi data secara dapat direproduksi tanpa bergantung pada versi R -----
# LCG Park-Miller dipakai hanya untuk mengacak urutan baris yang dibagi.
# Tidak menggunakan Rings untuk membagi data.
m <- 2147483647
state <- 2026
skor_acak <- numeric(nrow(d))
for (i in seq_len(nrow(d))) {
  state <- (48271 * state) %% m
  skor_acak[i] <- state
}
urutan <- order(skor_acak)
n_latih <- floor(0.8 * nrow(d))
id_latih <- urutan[seq_len(n_latih)]
id_uji <- urutan[(n_latih + 1L):nrow(d)]
latih <- d[id_latih, , drop = FALSE]
uji <- d[id_uji, , drop = FALSE]
cat("\nLANGKAH 4: PEMBAGIAN DATA\n")
cat("Latih:", nrow(latih), "Uji:", nrow(uji), "\n")

# 5. CV 5 lipatan: model selalu dilatih ulang di setiap 4/5 data latih ------
metrik <- function(aktual, prediksi) {
  e <- aktual - prediksi
  c(MAE = mean(abs(e)), RMSE = sqrt(mean(e^2)),
    R2 = 1 - sum(e^2) / sum((aktual - mean(aktual))^2))
}
pakai_pohon <- requireNamespace("rpart", quietly = TRUE)
pakai_rf <- requireNamespace("randomForest", quietly = TRUE)
if (!pakai_pohon) message("rpart belum tersedia: model pohon dilewati.")
if (!pakai_rf) message("Random Forest dilewati. Opsional: install.packages('randomForest')")

nama_model <- c("Rata-rata", "Regresi sederhana", "Regresi berganda")
if (pakai_pohon) nama_model <- c(nama_model, "Pohon regresi")
if (pakai_rf) nama_model <- c(nama_model, "Random Forest")
pred_cv <- setNames(lapply(nama_model,
                           function(z) rep(NA_real_, nrow(latih))), nama_model)
fold <- rep(1:5, length.out = nrow(latih))

for (k in 1:5) {
  tr <- latih[fold != k, , drop = FALSE]
  vl <- latih[fold == k, , drop = FALSE]
  pred_cv[["Rata-rata"]][fold == k] <- mean(tr$Rings)
  lm_s <- lm(Rings ~ Shell_weight, data = tr)
  pred_cv[["Regresi sederhana"]][fold == k] <- predict(lm_s, newdata = vl)
  lm_b <- lm(rumus_penuh, data = tr)
  pred_cv[["Regresi berganda"]][fold == k] <- predict(lm_b, newdata = vl)
  if (pakai_pohon) {
    pohon <- rpart::rpart(rumus_penuh, data = tr, method = "anova",
                           control = rpart::rpart.control(
                             cp = 0.005, minbucket = 15, xval = 0))
    pred_cv[["Pohon regresi"]][fold == k] <- predict(pohon, newdata = vl)
  }
  if (pakai_rf) {
    set.seed(2026 + k)
    hutan <- randomForest::randomForest(rumus_penuh, data = tr,
                                        ntree = 300, mtry = 3)
    pred_cv[["Random Forest"]][fold == k] <- predict(hutan, newdata = vl)
  }
}
if (anyNA(unlist(pred_cv))) stop("Ada prediksi validasi silang yang kosong.")
cv <- t(vapply(pred_cv, function(z) metrik(latih$Rings, z), numeric(3)))
cat("\nLANGKAH 5: VALIDASI SILANG PADA DATA LATIH\n")
print(round(cv, 4))

# 6. Latih sekali pada seluruh data latih, nilai sekali pada data uji ------
pred_uji <- list("Rata-rata" = rep(mean(latih$Rings), nrow(uji)))
lm_s <- lm(Rings ~ Shell_weight, data = latih)
pred_uji[["Regresi sederhana"]] <- predict(lm_s, newdata = uji)
lm_b <- lm(rumus_penuh, data = latih)
pred_uji[["Regresi berganda"]] <- predict(lm_b, newdata = uji)
if (pakai_pohon) {
  pohon <- rpart::rpart(rumus_penuh, data = latih, method = "anova",
                         control = rpart::rpart.control(
                           cp = 0.005, minbucket = 15, xval = 0))
  pred_uji[["Pohon regresi"]] <- predict(pohon, newdata = uji)
}
if (pakai_rf) {
  set.seed(3030)
  hutan <- randomForest::randomForest(rumus_penuh, data = latih,
                                      ntree = 300, mtry = 3, importance = TRUE)
  pred_uji[["Random Forest"]] <- predict(hutan, newdata = uji)
}
skor_uji <- t(vapply(pred_uji, function(z) metrik(uji$Rings, z), numeric(3)))
hasil <- data.frame(Model = rownames(cv),
                    CV_MAE = cv[, "MAE"], CV_RMSE = cv[, "RMSE"],
                    CV_R2 = cv[, "R2"],
                    Uji_MAE = skor_uji[, "MAE"],
                    Uji_RMSE = skor_uji[, "RMSE"],
                    Uji_R2 = skor_uji[, "R2"], row.names = NULL)
hasil <- hasil[order(hasil$CV_RMSE), , drop = FALSE]
cat("\nLANGKAH 6: PERBANDINGAN AKHIR\n")
print(hasil, digits = 4, row.names = FALSE)
cat("Pilih model menurut CV_RMSE terkecil; laporkan skor uji sekali saja.\n")
cat("MAE/RMSE diukur dalam Rings. R2 dapat negatif pada data uji.\n")

# 7. Simpan tabel dan diagnostik -------------------------------------------
folder_hasil <- output_dir
dir.create(folder_hasil, showWarnings = FALSE, recursive = TRUE)
write.csv(hasil, file.path(folder_hasil, "perbandingan_model.csv"),
          row.names = FALSE)
prediksi_tabel <- data.frame(baris_asli = id_uji,
                            Rings_aktual = uji$Rings,
                            Rata_rata = pred_uji[["Rata-rata"]],
                            OLS_sederhana = pred_uji[["Regresi sederhana"]],
                            OLS_berganda = pred_uji[["Regresi berganda"]])
if (pakai_pohon) prediksi_tabel$Pohon_regresi <- pred_uji[["Pohon regresi"]]
if (pakai_rf) prediksi_tabel$Random_Forest <- pred_uji[["Random Forest"]]
write.csv(prediksi_tabel, file.path(folder_hasil, "prediksi_data_uji.csv"),
          row.names = FALSE)
write.csv(hc3(mod_infer),
          file.path(folder_hasil, "inferensi_sederhana_HC3.csv"),
          row.names = FALSE)
png(file.path(folder_hasil, "diagnostik_regresi_berganda.png"),
    width = 1000, height = 800)
par(mfrow = c(2, 2))
plot(mod_penuh)
dev.off()

# 8. Tambahan paket: audit, VIF per kolom desain, manifest split dan model.
write.csv(hc3(mod_penuh), file.path(folder_hasil, "inferensi_berganda_HC3.csv"), row.names = FALSE)
Xv <- model.matrix(mod_penuh)[, -1, drop = FALSE]
vif <- vapply(seq_len(ncol(Xv)), function(j) {
  r2j <- summary(lm(Xv[, j] ~ Xv[, -j, drop = FALSE]))$r.squared
  1 / (1 - r2j)
}, numeric(1))
vif_tabel <- data.frame(Kolom_desain = colnames(Xv), VIF = vif)
write.csv(vif_tabel, file.path(folder_hasil, "vif_kolom_desain.csv"), row.names = FALSE)
# SexI dan SexM adalah VIF dummy individual, BUKAN GVIF faktor Sex.
flag <- d$Height <= 0 | d$Height > 0.3
audit <- data.frame(baris_asli = which(flag), d[flag, , drop = FALSE])
write.csv(audit, file.path(folder_hasil, "audit_height.csv"), row.names = FALSE)
manifest <- data.frame(baris_asli = seq_len(nrow(d)), bagian = "uji", fold = NA_integer_)
manifest$bagian[id_latih] <- "latih"
manifest$fold[id_latih] <- fold
write.csv(manifest, file.path(folder_hasil, "split_dan_fold.csv"), row.names = FALSE)
write.csv(data.frame(baris_asli = id_latih, Fold = fold, Rings = latih$Rings,
  as.data.frame(pred_cv, check.names = FALSE)),
  file.path(folder_hasil, "prediksi_oof.csv"), row.names = FALSE)
manual <- c(n=n, jumlah_x=sum(x), jumlah_y=sum(y), jumlah_x2=sum(x^2),
  jumlah_xy=sum(x*y), Sxx=Sxx, Sxy=Sxy, b0=b0_manual, b1=b1_manual,
  SSE=SSE, SST=SST, R2=R2_manual)
write.csv(data.frame(Statistik=names(manual), Nilai=unname(manual)),
  file.path(folder_hasil, "perhitungan_manual.csv"), row.names=FALSE)
write.csv(data.frame(Variabel = names(d)[-1],
  Korelasi_semua = vapply(d[-1], cor, numeric(1), y = d$Rings),
  Korelasi_latih = vapply(latih[-1], cor, numeric(1), y = latih$Rings)),
  file.path(folder_hasil, "korelasi.csv"), row.names = FALSE)

# 9. Ketidakpastian kinerja: bootstrap berpasangan pada baris uji.
# Tambahan terhadap skrip asli. Model tidak dilatih ulang; CI kondisional,
# bukan interval prediksi individu dan bukan ketidakpastian proses training.
set.seed(5050)
boot_rmse <- matrix(NA_real_, nrow = bootstrap_B, ncol = length(nama_model),
                    dimnames = list(NULL, nama_model))
for (b in seq_len(bootstrap_B)) {
  ii <- sample.int(nrow(uji), size = nrow(uji), replace = TRUE)
  boot_rmse[b, ] <- vapply(pred_uji, function(p)
    metrik(uji$Rings[ii], p[ii])["RMSE"], numeric(1))
}
ci <- t(apply(boot_rmse, 2, quantile, probs = c(0.025, 0.975)))
boot_tabel <- data.frame(Model = colnames(boot_rmse),
  RMSE = skor_uji[, "RMSE"], CI95_bawah = ci[,1], CI95_atas = ci[,2], row.names = NULL)
write.csv(boot_tabel, file.path(folder_hasil, "bootstrap_RMSE_kondisional.csv"), row.names = FALSE)
delta <- boot_rmse[, "Random Forest"] - boot_rmse[, "Regresi berganda"]
selisih <- data.frame(Kontras = "RMSE RF - RMSE regresi berganda",
  Selisih = skor_uji["Random Forest","RMSE"] - skor_uji["Regresi berganda","RMSE"],
  CI95_bawah = unname(quantile(delta,0.025)), CI95_atas = unname(quantile(delta,0.975)))
write.csv(selisih, file.path(folder_hasil, "selisih_RMSE_RF_OLS.csv"), row.names = FALSE)

# 10. Grafik tunggal agar mudah dipakai ulang oleh notebook/dashboard.
simpan_plot <- function(nama, expr) {
  png(file.path(folder_hasil,nama), width=1200, height=750, res=140)
  on.exit(dev.off(), add=TRUE)
  eval(substitute(expr), parent.frame())
}
simpan_plot("distribusi_rings.png", hist(d$Rings,
  breaks=seq(0.5,max(d$Rings)+0.5,by=1), main="Distribusi Rings", xlab="Rings", ylab="Frekuensi"))
simpan_plot("shell_vs_rings.png", {
  plot(d$Shell_weight, d$Rings, pch=16, cex=.35, xlab="Shell_weight (skala CSV)", ylab="Rings")
  abline(mod_infer,lwd=2)
})
simpan_plot("residual_fitted.png", plot(mod_penuh, which=1))
simpan_plot("qq_residual.png", plot(mod_penuh, which=2))
simpan_plot("cooks_distance.png", plot(mod_penuh, which=4))

# Objek prediktif hanya dilatih pada data latih, bukan mod_penuh seluruh data.
model_prediktif <- list("Rata-rata" = mean(latih$Rings),
  "Regresi sederhana" = lm_s, "Regresi berganda" = lm_b,
  "Pohon regresi" = pohon, "Random Forest" = hutan)
bundle <- list(data = d, latih = latih, uji = uji, hasil = hasil,
  model_prediktif = model_prediktif, infer_sederhana = mod_infer,
  infer_berganda = mod_penuh, hc3_sederhana = hc3(mod_infer),
  hc3_berganda = hc3(mod_penuh), vif = vif_tabel, audit = audit,
  pred_uji = pred_uji, bootstrap = boot_tabel, delta = selisih,
  split = manifest, model_pilihan_cv = hasil$Model[1L],
  sensitivitas = c(semua=coef(mod_penuh)["Height"],
    tanpa_ekstrem=coef(mod_sensitivitas)["Height"]))
saveRDS(bundle, file.path(folder_hasil, "model_dan_hasil.rds"))
capture.output(sessionInfo(), file=file.path(folder_hasil,"sessionInfo.txt"))
write.csv(data.frame(Paket=c("rpart","randomForest"),
  Versi=vapply(c("rpart","randomForest"), function(p) as.character(packageVersion(p)), character(1))),
  file.path(folder_hasil,"versi_paket.csv"), row.names=FALSE)
cat("Hasil R disimpan di:", normalizePath(folder_hasil), "\n")
invisible(bundle)
}

# Menjalankan langsung dari terminal: Rscript 01_Analisis_Abalone.R [CSV] [FOLDER]
# source() di RStudio hanya mendefinisikan fungsi, tidak menjalankan analisis.
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly=TRUE)
  csv <- if (length(args)>=1L) args[1L] else "data/abalone.csv"
  out <- if (length(args)>=2L) args[2L] else "hasil_R"
  analisis_abalone(csv, out)
}
