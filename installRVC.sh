#!/bin/bash
gpu="$1"
customPath="$2"
fullPath=""
rocmLink="https://download.pytorch.org/whl/rocm5.4.2"
huggin=("pretrained/D32k.pth" "pretrained/D40k.pth" "pretrained/D48k.pth" "pretrained/G32k.pth" "pretrained/G40k.pth" "pretrained/G48k.pth" "pretrained/f0D32k.pth" "pretrained/f0D40k.pth" "pretrained/f0D48k.pth" "pretrained/f0G32k.pth" "pretrained/f0G40k.pth" "pretrained/f0G48k.pth" "pretrained_v2/D32k.pth" "pretrained_v2/D40k.pth" "pretrained_v2/D48k.pth" "pretrained_v2/G32k.pth" "pretrained_v2/G40k.pth" "pretrained_v2/G48k.pth" "pretrained_v2/f0D32k.pth" "pretrained_v2/f0D40k.pth" "pretrained_v2/f0D48k.pth" "pretrained_v2/f0G32k.pth" "pretrained_v2/f0G40k.pth" "pretrained_v2/f0G48k.pth" "uvr5_weights/HP2-人声vocals+非人声instrumentals.pth" "uvr5_weights/HP2_all_vocals.pth" "uvr5_weights/HP3_all_vocals.pth" "uvr5_weights/HP5-主旋律人声vocals+其他instrumentals.pth" "uvr5_weights/HP5_only_main_vocal.pth" "uvr5_weights/VR-DeEchoAggressive.pth" "uvr5_weights/VR-DeEchoDeReverb.pth" "uvr5_weights/VR-DeEchoNormal.pth" "weights/白菜357k.pt" "hubert_base.pt" "rmvpe.pt")
usage()
{
	printf "\nusage: ./installRVC.sh amd/nvidia/cpu optional/path"
}
cde()
{
	cd "$1" || exit 3
}
depCheck()
{
	printf -- "checking for %s: " "$1"
	if ! command -v "$1" &> /dev/null
	then
		printf "missing"
		exit 1
	fi
	printf "found\n"
}
dirCheck()
{
	if [ ! -d "$1" ]
	then
		mkdir "$1" || exit 5
	fi
}
makeBin()
{
	printf "making starting/updating bash script for %s\n" "$gpu"
	printf -- "#!/bin/bash\ncd %s\nsource venv-3.10/bin/activate\nusage()\n{\n\tprintf \"usage: RVC start/update/ustart\\\nustart = update+start\"\n}\nupdate()\n{\n\tgit pull\n\tTORCH_COMMAND='venv-3.10/bin/python venv-3.10/bin/pip install torch torchvision torchaudio " "$1" > RVC
	if [ "$gpu" = "amd" ]
	then
		printf -- "--extra-index-url %s'" "$rocmLink" >> RVC
	elif [ "$gpu" = "cpu" ]
	then
		printf -- "--extra-index-url https://download.pytorch.org/whl/cpu'" >> RVC
	fi
	printf -- "\n}\nstart()\n{\n\tPYTORCH_HIP_ALLOC_CONF=garbage_collection_threshold:0.9,max_split_size_mb:512 venv-3.10/bin/python infer-web.py\n}\nustart()\n{\n\tupdate\n\tstart\n}\nfor i in "\"'$@'\""\ndo\n\tif type "\"'$i'\"" &>/dev/null\n\tthen\n\t\t"\"'$i'\"'\n\t\t'"\n\telse\n\t\tusage\n\t\texit\n\tfi\ndone\nusage" >> RVC
	chmod +x RVC
	printf "sudo required for moving the script to /bin\n"
	sh -c "sudo mv RVC /bin/RVC"
}
if [ "$gpu" = "amd" ] || [ "$gpu" = "nvidia" ] || [ "$gpu" = "cpu" ]
then
	:
else
	printf "usage: ./installRVC.sh amd/nvidia/cpu"
	exit 4
fi
clear
depCheck wget
depCheck git
printf -- "python3.10 is required because numba-0.56.4 requires python >=3.7 <3.11\n"
depCheck python3.10
if [ -z "$customPath" ]
then
	read -r -p "customPath is not set, do you want to install to default path? [y/N] " response
	if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
	then
		fullPath="$HOME/Programs/RVC/Retrieval-based-Voice-Conversion-WebUI"
		printf "\ncustomPath not set, installing to %s/Programs/RVC\n" "$HOME"
		cde "$HOME"
		dirCheck Programs
		cde "Programs"
		dirCheck RVC
		cde "RVC"
		touch RVC
		makeBin "$fullPath" "$gpu"
	else
		usage
		exit 6
	fi
else
	fullPath="$customPath/RVC/Retrieval-based-Voice-Conversion-WebUI"
	printf "customPath not set, installing to %s/RVC\n" "$customPath"
	cde "$customPath"
	dirCheck RVC
	cde "RVC"
	makeBin "$fullPath" "$gpu"
fi
git clone "https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI.git"
cde "Retrieval-based-Voice-Conversion-WebUI"
python3.10 -m venv venv-3.10
source venv-3.10/bin/activate
venv-3.10/bin/python venv-3.10/bin/pip install --upgrade pip wheel
if [ "$gpu" = "amd" ]
then
	venv-3.10/bin/python venv-3.10/bin/pip install torch torchvision torchaudio --extra-index-url $rocmLink
elif [ "$gpu" = "nvidia" ]
then
	venv-3.10/bin/python venv-3.10/bin/pip install torch torchvision torchaudio
elif [ "$gpu" = "cpu" ]
then
	venv-3.10/bin/python venv-3.10/bin/pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cpu
fi
venv-3.10/bin/python venv-3.10/bin/pip install -r requirements.txt
venv-3.10/bin/python venv-3.10/bin/pip install huggingface_hub
for i in "${huggin[@]}"
do
	venv-3.10/bin/python -c "from huggingface_hub import hf_hub_download;hf_hub_download(repo_id='lj1995/VoiceConversionWebUI',filename='$i',local_dir='./',local_dir_use_symlinks=False)"
done
deactivate
printf "installation complete\nto install models go to https://huggingface.co/models?pipeline_tag=audio-to-audio to download them, to \"install\" the .pth(model) files put them in the %s/weights folder" "$fullPath"