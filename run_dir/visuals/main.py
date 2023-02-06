from utils import* 

parser = argparse.ArgumentParser(
                    prog = 'ProgramName',
                    description = 'What the program does',
                    epilog = 'Text at the bottom of help')

parser.add_argument('--save', action='store_true')  # if save used then fig is saved, otherwise plt.show
parser.add_argument('--name')  # if save used then fig is saved, otherwise plt.show
args = parser.parse_args()

path = "/Users/sbhardwa/Library/CloudStorage/OneDrive-UniversityofEdinburgh/Coding/hpcg/run_dir/4Feb"
HPCG_iocomp_timers(path)

